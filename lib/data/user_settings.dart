import 'package:cloud_firestore/cloud_firestore.dart';

/// Preferencias reales del usuario — nombre y qué tipos de
/// notificación quiere ver en la pantalla de Notificaciones. Vive en
/// users/{uid} (el documento raíz, no una subcolección).
class UserSettings {
  const UserSettings({
    required this.name,
    required this.notifyRegisterReminder,
    required this.notifyDailySummary,
    required this.notifySpendingAlerts,
    required this.notifySavingsGoals,
  });

  static const empty = UserSettings(
    name: '',
    notifyRegisterReminder: true,
    notifyDailySummary: true,
    notifySpendingAlerts: true,
    notifySavingsGoals: true,
  );

  final String name;
  final bool notifyRegisterReminder;
  final bool notifyDailySummary;
  final bool notifySpendingAlerts;
  final bool notifySavingsGoals;

  factory UserSettings.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) return empty;
    return UserSettings(
      name: data['name'] as String? ?? '',
      notifyRegisterReminder: data['notifyRegisterReminder'] as bool? ?? true,
      notifyDailySummary: data['notifyDailySummary'] as bool? ?? true,
      notifySpendingAlerts: data['notifySpendingAlerts'] as bool? ?? true,
      notifySavingsGoals: data['notifySavingsGoals'] as bool? ?? true,
    );
  }
}

/// CRUD de las preferencias del usuario, en el documento users/{uid}.
class UserSettingsRepository {
  UserSettingsRepository(this.uid, {FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> get _doc =>
      _firestore.collection('users').doc(uid);

  Stream<UserSettings> watchSettings() {
    return _doc.snapshots().map(UserSettings.fromFirestore);
  }

  Future<void> updateName(String name) =>
      _doc.set({'name': name}, SetOptions(merge: true));

  Future<void> updateNotificationPref(String field, bool value) =>
      _doc.set({field: value}, SetOptions(merge: true));

  /// Borra el documento de preferencias — parte de "Eliminar cuenta".
  Future<void> deleteProfile() => _doc.delete();
}
