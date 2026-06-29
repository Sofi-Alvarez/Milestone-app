import 'package:cloud_firestore/cloud_firestore.dart';

import 'goal.dart';

/// CRUD de metas sobre Firestore, en users/{uid}/goals.
/// Requiere un usuario autenticado (real o anónimo) — ver
/// AuthService.ensureSignedIn en lib/features/auth/auth_service.dart.
class GoalsRepository {
  GoalsRepository(this.uid, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _goalsRef =>
      _firestore.collection('users').doc(uid).collection('goals');

  Stream<List<Goal>> watchGoals() {
    return _goalsRef.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Goal.fromFirestore).toList(),
        );
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
  /// la marca como lograda automáticamente.
  Future<void> addSavings(String goalId, double amount) {
    return _firestore.runTransaction((transaction) async {
      final ref = _goalsRef.doc(goalId);
      final snapshot = await transaction.get(ref);
      final goal = Goal.fromFirestore(snapshot);
      final newSaved = goal.savedAmount + amount;
      final achieved = newSaved >= goal.targetAmount;
      transaction.update(ref, {
        'savedAmount': newSaved,
        'lastEntryAmount': amount,
        if (achieved) 'lifecycle': GoalLifecycle.achieved.name,
        if (achieved) 'achievedAt': Timestamp.now(),
      });
    });
  }
}
