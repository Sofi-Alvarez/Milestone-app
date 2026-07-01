import 'package:cloud_firestore/cloud_firestore.dart';

import 'transaction.dart';
import 'transaction_category.dart';

/// CRUD de ingresos/gastos y pagos planificados, en users/{uid}/transactions
/// y users/{uid}/scheduledPayments.
class TransactionsRepository {
  TransactionsRepository(this.uid, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('users').doc(uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> get _scheduledRef =>
      _firestore.collection('users').doc(uid).collection('scheduledPayments');

  Future<String> createTransaction({
    required TransactionType type,
    required double amount,
    required String categoryId,
    required String categoryLabel,
    required DateTime date,
    required String note,
    String? scheduledPaymentId,
  }) async {
    final doc = await _transactionsRef.add({
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'categoryLabel': categoryLabel,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': Timestamp.now(),
      'scheduledPaymentId': ?scheduledPaymentId,
    });
    return doc.id;
  }

  Future<void> updateTransaction(
    String id, {
    required TransactionType type,
    required double amount,
    required String categoryId,
    required String categoryLabel,
    required DateTime date,
    required String note,
  }) {
    return _transactionsRef.doc(id).update({
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'categoryLabel': categoryLabel,
      'date': Timestamp.fromDate(date),
      'note': note,
    });
  }

  Future<void> deleteTransaction(String id) => _transactionsRef.doc(id).delete();

  Future<void> deleteScheduledPayment(String id) => _scheduledRef.doc(id).delete();

  Stream<List<MoneyTransaction>> watchTransactions({int limit = 50}) {
    return _transactionsRef
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map(MoneyTransaction.fromFirestore).toList());
  }

  /// Suma de todas las transacciones (ingresos positivos, gastos
  /// negativos) — el "Dinero disponible" real del Home.
  Stream<double> watchBalance() {
    return _transactionsRef.snapshots().map(
          (s) => s.docs
              .map(MoneyTransaction.fromFirestore)
              .fold<double>(0, (total, t) => total + t.signedAmount),
        );
  }

  Future<String> createScheduledPayment(ScheduledPayment payment) async {
    final doc = await _scheduledRef.add(payment.toFirestore());
    return doc.id;
  }

  Stream<List<ScheduledPayment>> watchScheduledPayments() {
    return _scheduledRef
        .orderBy('date')
        .snapshots()
        .map((s) => s.docs.map(ScheduledPayment.fromFirestore).toList());
  }

  /// Registros planificados activos cuya fecha ya llegó — la base real
  /// de la card de acción en el Home y de las notificaciones.
  Stream<List<ScheduledPayment>> watchDueScheduledPayments() {
    // Solo filtramos por isActive en el servidor (un único campo, no
    // necesita índice compuesto) y chequeamos la fecha en el cliente —
    // la colección por usuario es chica, así que es liviano.
    return _scheduledRef
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map(
          (s) => s.docs
              .map(ScheduledPayment.fromFirestore)
              .where((p) => p.isDue)
              .toList(),
        );
  }

  /// El usuario confirma el registro planificado: crea la transacción
  /// real de hoy y, si es recurrente, avanza a la próxima fecha (o lo
  /// desactiva si la serie terminó).
  Future<void> acceptScheduledPayment(ScheduledPayment payment) async {
    await createTransaction(
      type: payment.type,
      amount: payment.amount,
      categoryId: payment.categoryId,
      categoryLabel: payment.categoryLabel,
      date: DateTime.now(),
      note: payment.note,
      scheduledPaymentId: payment.id,
    );

    if (payment.frequency == PaymentFrequency.once) {
      await _scheduledRef.doc(payment.id).update({
        'isActive': false,
        'lastAcceptedAt': Timestamp.now(),
      });
      return;
    }

    final next = addRecurrenceInterval(
      payment.nextDueDate,
      payment.recurrenceUnit!,
      payment.recurrenceInterval ?? 1,
    );
    final seriesEnded = switch (payment.recurrenceEndType) {
      RecurrenceEndType.untilDate =>
        payment.recurrenceEndDate != null && next.isAfter(payment.recurrenceEndDate!),
      RecurrenceEndType.occurrences =>
        (payment.recurrenceOccurrences ?? 1) <= 1,
      _ => false,
    };

    await _scheduledRef.doc(payment.id).update({
      'nextDueDate': Timestamp.fromDate(next),
      'isActive': !seriesEnded,
      if (seriesEnded) 'lastAcceptedAt': Timestamp.now(),
      if (payment.recurrenceEndType == RecurrenceEndType.occurrences)
        'recurrenceOccurrences': (payment.recurrenceOccurrences ?? 1) - 1,
    });
  }

  /// El usuario pospone el registro planificado a otra fecha, sin
  /// crear ninguna transacción todavía.
  Future<void> rescheduleScheduledPayment(String id, DateTime newDate) {
    return _scheduledRef.doc(id).update({'nextDueDate': Timestamp.fromDate(newDate)});
  }

  /// Edición rápida desde el detalle (monto/categoría/próxima fecha) —
  /// sin tocar frecuencia, notificaciones ni recurrencia, eso vive en
  /// la Configuración avanzada. Siempre reactiva el registro
  /// (isActive: true): si estaba "Realizado" y se le cambian los
  /// datos, vuelve a Programado/Vencido según corresponda y habilita
  /// "Aceptar ahora" de nuevo — editar invalida el "ya está resuelto".
  Future<void> updateScheduledPaymentFields(
    String id, {
    required TransactionType type,
    required double amount,
    required String categoryId,
    required String categoryLabel,
    required DateTime nextDueDate,
  }) {
    return _scheduledRef.doc(id).update({
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'categoryLabel': categoryLabel,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'isActive': true,
    });
  }

  /// Edición completa desde "Configuración avanzada" — todos los
  /// campos del formulario, preservando createdAt e isActive.
  Future<void> updateScheduledPayment(String id, ScheduledPayment payment) {
    final data = payment.toFirestore()..remove('createdAt');
    return _scheduledRef.doc(id).update(data);
  }

  /// Borra todas las transacciones y registros programados del usuario
  /// — usado por "Eliminar cuenta" en Perfil. Irreversible.
  Future<void> deleteAllData() async {
    final transactions = await _transactionsRef.get();
    final scheduled = await _scheduledRef.get();
    final batch = _firestore.batch();
    for (final doc in transactions.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in scheduled.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
