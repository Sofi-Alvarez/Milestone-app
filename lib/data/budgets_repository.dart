import 'package:cloud_firestore/cloud_firestore.dart';

import 'budget.dart';

/// CRUD de presupuestos sobre Firestore, en users/{uid}/budgets. Solo
/// puede haber un presupuesto vigente (activo o pausado, no vencido) a
/// la vez — se hace cumplir acá, no en la UI, para que valga sin
/// importar desde dónde se intente crear uno nuevo.
class BudgetsRepository {
  BudgetsRepository(this.uid, {FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection('users').doc(uid).collection('budgets');

  Stream<List<Budget>> watchBudgets() {
    return _ref.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Budget.fromFirestore).toList(),
        );
  }

  /// El presupuesto vigente ahora mismo (activo o pausado, no vencido
  /// ni cancelado) — a lo sumo uno. Se resuelve en el cliente porque la
  /// colección por usuario es chica.
  Stream<Budget?> watchCurrentBudget() {
    return watchBudgets().map(
      (budgets) => budgets.where((b) => b.isCurrent).isEmpty
          ? null
          : budgets.where((b) => b.isCurrent).first,
    );
  }

  Future<String> createBudget(Budget budget) async {
    final doc = await _ref.add(budget.toFirestore());
    return doc.id;
  }

  Future<void> updateBudget(String id, Budget budget) {
    return _ref.doc(id).update(budget.toFirestore());
  }

  Future<void> setStatus(String id, BudgetStatus status) {
    return _ref.doc(id).update({'status': status.name});
  }

  Future<void> deleteBudget(String id) {
    return _ref.doc(id).delete();
  }

  Future<void> deleteAllData() async {
    final docs = await _ref.get();
    final batch = _firestore.batch();
    for (final doc in docs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
