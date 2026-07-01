import 'package:cloud_firestore/cloud_firestore.dart';

/// Un aporte de ahorro registrado contra una meta — la fuente real de
/// "Movimientos recientes" y del cálculo de "Ahorro mensual" en el Home.
class Movement {
  const Movement({
    required this.id,
    required this.goalId,
    required this.goalTitle,
    required this.amount,
    required this.createdAt,
  });

  final String id;
  final String goalId;
  final String goalTitle;
  final double amount;
  final DateTime createdAt;

  bool get isPositive => amount >= 0;

  factory Movement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Movement(
      id: doc.id,
      goalId: data['goalId'] as String? ?? '',
      goalTitle: data['goalTitle'] as String? ?? 'Meta',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// "Hace 2 minutos" / "Hace 3 horas" / "Hace 5 días" / "15 Ago 2023".
String formatRelativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'Recién';
  if (diff.inMinutes < 60) {
    final m = diff.inMinutes;
    return m == 1 ? 'Hace 1 minuto' : 'Hace $m minutos';
  }
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return h == 1 ? 'Hace 1 hora' : 'Hace $h horas';
  }
  if (diff.inDays < 7) {
    final d = diff.inDays;
    return d == 1 ? 'Hace 1 día' : 'Hace $d días';
  }
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// "Hoy, 18:30hs" / "Ayer, 09:05hs" / "26 jun, 18:30hs" — siempre en
/// formato 24hs, igual en toda la app.
String formatMovementTimestamp(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  final time = formatTime24h(date);

  if (day == today) return 'Hoy, $time';
  if (day == today.subtract(const Duration(days: 1))) return 'Ayer, $time';
  const months = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];
  return '${date.day} ${months[date.month - 1]}, $time';
}

/// "18:30hs" — formato 24hs estándar de la app.
String formatTime24h(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:${minute}hs';
}
