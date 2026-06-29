import 'package:cloud_firestore/cloud_firestore.dart';

enum GoalLifecycle { active, paused, achieved }

enum GoalPace { onTime, late, ahead }

/// Meta de ahorro con sus cálculos derivados (progreso, ritmo, sugerido).
/// Nada de esto es hardcodeado: todo se deriva de [savedAmount],
/// [targetAmount], [createdAt] y [targetDate] reales.
class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.createdAt,
    required this.targetDate,
    required this.lifecycle,
    this.lastEntryAmount,
    this.achievedAt,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime createdAt;
  final DateTime? targetDate;
  final GoalLifecycle lifecycle;
  final double? lastEntryAmount;
  final DateTime? achievedAt;

  double get progress =>
      targetAmount <= 0 ? 0 : (savedAmount / targetAmount).clamp(0, 1);

  bool get isAchieved =>
      lifecycle == GoalLifecycle.achieved || savedAmount >= targetAmount;

  /// Cuánto falta ahorrar por día para llegar a tiempo, a partir de hoy.
  double get suggestedDaily {
    if (targetDate == null) return 0;
    final remaining = targetAmount - savedAmount;
    if (remaining <= 0) return 0;
    final days = targetDate!.difference(DateTime.now()).inDays;
    if (days <= 0) return remaining;
    return remaining / days;
  }

  /// Tiempo restante hasta la fecha objetivo, en semanas.
  int get estimatedWeeksLeft {
    if (targetDate == null) return 0;
    final days = targetDate!.difference(DateTime.now()).inDays;
    return (days / 7).ceil().clamp(0, 100000);
  }

  /// Compara el progreso real contra el progreso esperado a esta fecha
  /// (proporcional al tiempo transcurrido desde la creación) para decidir
  /// si la meta va en tiempo, atrasada, o adelantada.
  GoalPace get pace {
    if (targetDate == null) return GoalPace.onTime;
    final totalDays = targetDate!.difference(createdAt).inDays;
    if (totalDays <= 0) return GoalPace.onTime;
    final elapsedDays = DateTime.now().difference(createdAt).inDays;
    final expectedProgress = (elapsedDays / totalDays).clamp(0.0, 1.0);
    final diff = progress - expectedProgress;
    if (diff > 0.05) return GoalPace.ahead;
    if (diff < -0.05) return GoalPace.late;
    return GoalPace.onTime;
  }

  String get paceLabel {
    switch (pace) {
      case GoalPace.onTime:
        return 'En tiempo';
      case GoalPace.late:
        return 'Atrasado';
      case GoalPace.ahead:
        return 'Adelantado';
    }
  }

  /// "Finaliza en X meses" / "Requiere $X/mes" / "Ventaja de X semanas".
  String get paceNote {
    if (targetDate == null) return 'Sin fecha objetivo';
    final totalDays = targetDate!.difference(createdAt).inDays;
    final daysLeft = targetDate!.difference(DateTime.now()).inDays;
    switch (pace) {
      case GoalPace.onTime:
        final months = (daysLeft / 30).ceil().clamp(0, 100000);
        return 'Finaliza en $months meses';
      case GoalPace.late:
        final monthsLeft = (daysLeft / 30).clamp(1, 100000);
        final remaining = targetAmount - savedAmount;
        final perMonth = remaining / monthsLeft;
        return 'Requiere ${_formatMoney(perMonth)}/mes';
      case GoalPace.ahead:
        if (totalDays <= 0) return 'Ventaja de 0 semanas';
        final elapsedDays = DateTime.now().difference(createdAt).inDays;
        final expectedProgress = (elapsedDays / totalDays).clamp(0.0, 1.0);
        final aheadDays = ((progress - expectedProgress) * totalDays).round();
        final weeks = (aheadDays / 7).round().clamp(0, 100000);
        return 'Ventaja de $weeks semanas';
    }
  }

  Goal copyWith({
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? targetDate,
    GoalLifecycle? lifecycle,
    double? lastEntryAmount,
    DateTime? achievedAt,
  }) {
    return Goal(
      id: id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      savedAmount: savedAmount ?? this.savedAmount,
      createdAt: createdAt,
      targetDate: targetDate ?? this.targetDate,
      lifecycle: lifecycle ?? this.lifecycle,
      lastEntryAmount: lastEntryAmount ?? this.lastEntryAmount,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  factory Goal.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Goal(
      id: doc.id,
      title: data['title'] as String? ?? 'Sin título',
      targetAmount: (data['targetAmount'] as num?)?.toDouble() ?? 0,
      savedAmount: (data['savedAmount'] as num?)?.toDouble() ?? 0,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      targetDate: (data['targetDate'] as Timestamp?)?.toDate(),
      lifecycle: GoalLifecycle.values.firstWhere(
        (e) => e.name == data['lifecycle'],
        orElse: () => GoalLifecycle.active,
      ),
      lastEntryAmount: (data['lastEntryAmount'] as num?)?.toDouble(),
      achievedAt: (data['achievedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'targetDate': targetDate == null ? null : Timestamp.fromDate(targetDate!),
      'lifecycle': lifecycle.name,
      if (lastEntryAmount != null) 'lastEntryAmount': lastEntryAmount,
      if (achievedAt != null) 'achievedAt': Timestamp.fromDate(achievedAt!),
    };
  }
}

String _formatMoney(double value) {
  final rounded = value.round();
  final digits = rounded.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '\$$buffer';
}
