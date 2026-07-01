import 'package:cloud_firestore/cloud_firestore.dart';

import 'goal.dart';
import 'movement.dart';

/// CRUD de metas y movimientos sobre Firestore, en users/{uid}/goals y
/// users/{uid}/movements. Requiere un usuario autenticado (real o
/// anónimo) — ver AuthService.ensureSignedIn en
/// lib/features/auth/auth_service.dart.
class GoalsRepository {
  GoalsRepository(this.uid, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _goalsRef =>
      _firestore.collection('users').doc(uid).collection('goals');

  CollectionReference<Map<String, dynamic>> get _movementsRef =>
      _firestore.collection('users').doc(uid).collection('movements');

  Stream<List<Goal>> watchGoals() {
    return _goalsRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Goal.fromFirestore).toList(),
        );
  }

  /// Stream de una meta puntual — emite `null` si fue eliminada.
  Stream<Goal?> watchGoal(String goalId) {
    return _goalsRef
        .doc(goalId)
        .snapshots()
        .map((doc) => doc.exists ? Goal.fromFirestore(doc) : null);
  }

  Future<String> createGoal({
    required String title,
    required double targetAmount,
    required double savedAmount,
    required DateTime? targetDate,
  }) async {
    final doc = await _goalsRef.add({
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'createdAt': Timestamp.now(),
      'targetDate': targetDate == null ? null : Timestamp.fromDate(targetDate),
      'lifecycle': GoalLifecycle.active.name,
    });
    // El ahorro inicial es un movimiento real de hoy, así que cuenta
    // para "Ahorro mensual" del Home igual que cualquier otro aporte.
    if (savedAmount > 0) {
      await _movementsRef.add({
        'goalId': doc.id,
        'goalTitle': title,
        'amount': savedAmount,
        'createdAt': Timestamp.now(),
      });
    }
    return doc.id;
  }

  Future<void> updateGoal(
    String goalId, {
    required String title,
    required double targetAmount,
    required double savedAmount,
    required DateTime? targetDate,
  }) {
    return _goalsRef.doc(goalId).update({
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': targetDate == null ? null : Timestamp.fromDate(targetDate),
    });
  }

  Future<void> deleteGoal(String goalId) => _goalsRef.doc(goalId).delete();

  Future<void> pauseGoal(String goalId) =>
      _goalsRef.doc(goalId).update({'lifecycle': GoalLifecycle.paused.name});

  Future<void> resumeGoal(String goalId) =>
      _goalsRef.doc(goalId).update({'lifecycle': GoalLifecycle.active.name});

  /// Reinicia la meta: vuelve a activa y el ahorro a cero.
  Future<void> restartGoal(String goalId) => _goalsRef.doc(goalId).update({
        'lifecycle': GoalLifecycle.active.name,
        'savedAmount': 0,
      });

  /// Suma [amount] al ahorro de la meta. Si llega o supera el objetivo,
  /// la marca como lograda automáticamente. Devuelve `true` si esta
  /// llamada fue la que recién la completó (para disparar la
  /// celebración solo una vez, no en cada ahorro posterior).
  Future<bool> addSavings(String goalId, double amount) {
    final movementRef = _movementsRef.doc();
    return _firestore.runTransaction<bool>((transaction) async {
      final ref = _goalsRef.doc(goalId);
      final snapshot = await transaction.get(ref);
      final goal = Goal.fromFirestore(snapshot);
      final newSaved = goal.savedAmount + amount;
      final justAchieved =
          goal.lifecycle != GoalLifecycle.achieved && newSaved >= goal.targetAmount;
      transaction.update(ref, {
        'savedAmount': newSaved,
        'lastEntryAmount': amount,
        if (justAchieved) 'lifecycle': GoalLifecycle.achieved.name,
        if (justAchieved) 'achievedAt': Timestamp.now(),
      });
      transaction.set(movementRef, {
        'goalId': goalId,
        'goalTitle': goal.title,
        'amount': amount,
        'createdAt': Timestamp.now(),
      });
      return justAchieved;
    });
  }

  Stream<List<Movement>> watchRecentMovements({int limit = 10}) {
    return _movementsRef
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Movement.fromFirestore).toList());
  }

  /// Movimientos del mes calendario en curso — base real de "Ahorro
  /// mensual" en el Home (nada hardcodeado).
  /// Borra todas las metas y movimientos del usuario — usado por
  /// "Eliminar cuenta" en Perfil. Irreversible.
  Future<void> deleteAllData() async {
    final goals = await _goalsRef.get();
    final movements = await _movementsRef.get();
    final batch = _firestore.batch();
    for (final doc in goals.docs) {
      batch.delete(doc.reference);
    }
    for (final doc in movements.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Stream<List<Movement>> watchMovementsThisMonth() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    return _movementsRef
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Movement.fromFirestore).toList());
  }
}
