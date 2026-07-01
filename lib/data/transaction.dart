import 'package:cloud_firestore/cloud_firestore.dart';

import 'transaction_category.dart';

class MoneyTransaction {
  const MoneyTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.categoryLabel,
    required this.date,
    required this.note,
    required this.createdAt,
    this.scheduledPaymentId,
  });

  final String id;
  final TransactionType type;
  final double amount;
  final String categoryId;
  final String categoryLabel;
  final DateTime date;
  final String note;
  final DateTime createdAt;

  /// Si esta transacción se creó al aceptar un registro programado,
  /// acá queda el id de ese registro — así el Registro puede mostrar
  /// una sola card (la del programado, con su estado real) en vez de
  /// duplicar la misma transacción vista desde dos ángulos.
  final String? scheduledPaymentId;

  /// Positivo si es ingreso, negativo si es gasto — así sumar todas las
  /// transacciones da directamente el balance ("Dinero disponible").
  double get signedAmount => type == TransactionType.income ? amount : -amount;

  factory MoneyTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return MoneyTransaction(
      id: doc.id,
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.expense,
      ),
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      categoryId: data['categoryId'] as String? ?? '',
      categoryLabel: data['categoryLabel'] as String? ?? 'Otros',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      scheduledPaymentId: data['scheduledPaymentId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type.name,
      'amount': amount,
      'categoryId': categoryId,
      'categoryLabel': categoryLabel,
      'date': Timestamp.fromDate(date),
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      if (scheduledPaymentId != null) 'scheduledPaymentId': scheduledPaymentId,
    };
  }
}

enum PaymentFrequency { once, recurring }

enum RecurrenceUnit { daily, weekly, monthly, yearly }

enum RecurrenceEndType { forever, untilDate, occurrences }

enum PaymentNotification {
  none,
  onDueDate,
  oneDayBefore,
  threeDaysBefore,
  oneWeekBefore,
}

DateTime addRecurrenceInterval(
  DateTime date,
  RecurrenceUnit unit,
  int interval,
) {
  switch (unit) {
    case RecurrenceUnit.daily:
      return date.add(Duration(days: interval));
    case RecurrenceUnit.weekly:
      return date.add(Duration(days: 7 * interval));
    case RecurrenceUnit.monthly:
      return DateTime(
        date.year,
        date.month + interval,
        date.day,
        date.hour,
        date.minute,
      );
    case RecurrenceUnit.yearly:
      return DateTime(
        date.year + interval,
        date.month,
        date.day,
        date.hour,
        date.minute,
      );
  }
}

/// "Registro planificado" — no se ejecuta solo en la fecha. Cuando
/// [nextDueDate] llega, aparece como notificación y como card de acción
/// en el Home ("Aceptar" crea la transacción real / "Reprogramar" mueve
/// la fecha). [isActive] se apaga cuando un registro de una sola vez fue
/// aceptado, o cuando una serie recurrente terminó.
class ScheduledPayment {
  const ScheduledPayment({
    required this.id,
    required this.name,
    required this.type,
    required this.categoryId,
    required this.categoryLabel,
    required this.amount,
    required this.frequency,
    required this.date,
    required this.notification,
    this.recurrenceUnit,
    this.recurrenceInterval,
    this.recurrenceEndType,
    this.recurrenceEndDate,
    this.recurrenceOccurrences,
    required this.note,
    required this.createdAt,
    required this.nextDueDate,
    required this.isActive,
    this.lastAcceptedAt,
  });

  final String id;
  final String name;
  final TransactionType type;
  final String categoryId;
  final String categoryLabel;
  final double amount;
  final PaymentFrequency frequency;
  final DateTime date;
  final PaymentNotification notification;
  final RecurrenceUnit? recurrenceUnit;
  final int? recurrenceInterval;
  final RecurrenceEndType? recurrenceEndType;
  final DateTime? recurrenceEndDate;
  final int? recurrenceOccurrences;
  final String note;
  final DateTime createdAt;

  /// Próxima fecha en la que este registro debe pedirse al usuario.
  final DateTime nextDueDate;
  final bool isActive;

  /// Cuándo se tocó "Aceptar ahora" por última vez — es la fecha real
  /// que hay que usar para agrupar/mostrar horario una vez "Realizado",
  /// no [nextDueDate] (que es la fecha límite original).
  final DateTime? lastAcceptedAt;

  bool get isDue => isActive && !nextDueDate.isAfter(DateTime.now());

  /// La fecha "real" de este registro para agrupar/ordenar en listas:
  /// la de aceptación si ya fue realizado, si no la próxima fecha.
  DateTime get effectiveDate =>
      (!isActive ? lastAcceptedAt : null) ?? nextDueDate;

  factory ScheduledPayment.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ScheduledPayment(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: data['categoryId'] as String? ?? '',
      categoryLabel: data['categoryLabel'] as String? ?? 'Otros',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      frequency: PaymentFrequency.values.firstWhere(
        (e) => e.name == data['frequency'],
        orElse: () => PaymentFrequency.once,
      ),
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notification: PaymentNotification.values.firstWhere(
        (e) => e.name == data['notification'],
        orElse: () => PaymentNotification.none,
      ),
      recurrenceUnit: data['recurrenceUnit'] == null
          ? null
          : RecurrenceUnit.values.firstWhere(
              (e) => e.name == data['recurrenceUnit'],
            ),
      recurrenceInterval: (data['recurrenceInterval'] as num?)?.toInt(),
      recurrenceEndType: data['recurrenceEndType'] == null
          ? null
          : RecurrenceEndType.values.firstWhere(
              (e) => e.name == data['recurrenceEndType'],
            ),
      recurrenceEndDate: (data['recurrenceEndDate'] as Timestamp?)?.toDate(),
      recurrenceOccurrences: (data['recurrenceOccurrences'] as num?)?.toInt(),
      note: data['note'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      nextDueDate:
          (data['nextDueDate'] as Timestamp?)?.toDate() ??
          (data['date'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      isActive: data['isActive'] as bool? ?? true,
      lastAcceptedAt: (data['lastAcceptedAt'] as Timestamp?)?.toDate(),
    );
  }

  ScheduledPayment copyWith({DateTime? nextDueDate, bool? isActive}) {
    return ScheduledPayment(
      id: id,
      name: name,
      type: type,
      categoryId: categoryId,
      categoryLabel: categoryLabel,
      amount: amount,
      frequency: frequency,
      date: date,
      notification: notification,
      recurrenceUnit: recurrenceUnit,
      recurrenceInterval: recurrenceInterval,
      recurrenceEndType: recurrenceEndType,
      recurrenceEndDate: recurrenceEndDate,
      recurrenceOccurrences: recurrenceOccurrences,
      note: note,
      createdAt: createdAt,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'categoryId': categoryId,
      'categoryLabel': categoryLabel,
      'amount': amount,
      'frequency': frequency.name,
      'date': Timestamp.fromDate(date),
      'notification': notification.name,
      if (recurrenceUnit != null) 'recurrenceUnit': recurrenceUnit!.name,
      if (recurrenceInterval != null) 'recurrenceInterval': recurrenceInterval,
      if (recurrenceEndType != null)
        'recurrenceEndType': recurrenceEndType!.name,
      if (recurrenceEndDate != null)
        'recurrenceEndDate': Timestamp.fromDate(recurrenceEndDate!),
      if (recurrenceOccurrences != null)
        'recurrenceOccurrences': recurrenceOccurrences,
      'note': note,
      'createdAt': Timestamp.fromDate(createdAt),
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'isActive': isActive,
      if (lastAcceptedAt != null)
        'lastAcceptedAt': Timestamp.fromDate(lastAcceptedAt!),
    };
  }
}
