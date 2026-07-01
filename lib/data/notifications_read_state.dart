import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Última vez que el usuario marcó las notificaciones como leídas —
/// persiste localmente para que el indicador de "no leídas" en la
/// campana sobreviva a un reinicio de la app.
class NotificationsReadState {
  NotificationsReadState._();
  static final instance = NotificationsReadState._();

  static const _prefsKey = 'notifications_last_read_at';

  final ValueNotifier<DateTime?> lastReadAt = ValueNotifier(null);
  bool _loaded = false;

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_prefsKey);
    if (millis != null) {
      lastReadAt.value = DateTime.fromMillisecondsSinceEpoch(millis);
    }
  }

  Future<void> markAllRead() async {
    final now = DateTime.now();
    lastReadAt.value = now;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, now.millisecondsSinceEpoch);
  }
}
