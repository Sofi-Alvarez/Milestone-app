import 'package:cloud_firestore/cloud_firestore.dart';

/// General: un único límite total, sin distinguir categoría. Por
/// categorías: el límite se reparte entre asignaciones concretas.
enum BudgetType { general, byCategory }

enum BudgetStatus { active, paused, cancelled }

extension BudgetStatusLabel on BudgetStatus {
  String get label => switch (this) {
        BudgetStatus.active => 'Activo',
        BudgetStatus.paused => 'Pausado',
        BudgetStatus.cancelled => 'Cancelado',
      };
}

/// Un renglón de "presupuesto por categorías" — la categoría y el
/// límite que se le asignó. El monto gastado se calcula en vivo contra
/// las transacciones reales, nunca se persiste acá.
class BudgetCategoryAllocation {
  const BudgetCategoryAllocation({
    required this.categoryId,
    required this.categoryLabel,
    required this.limitAmount,
  });

  final String categoryId;
  final String categoryLabel;
  final double limitAmount;

  factory BudgetCategoryAllocation.fromMap(Map<String, dynamic> map) {
    return BudgetCategoryAllocation(
      categoryId: map['categoryId'] as String? ?? '',
      categoryLabel: map['categoryLabel'] as String? ?? 'Otros',
      limitAmount: (map['limitAmount'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'categoryLabel': categoryLabel,
        'limitAmount': limitAmount,
      };
}

/// Un presupuesto por período — solo puede haber uno activo o pausado
/// a la vez (se hace cumplir en [BudgetsRepository]). Se "cierra" solo
/// por fecha (ver [isPastEnd]), no queda un estado persistido para eso:
/// pasada la fecha límite deja de contar como el presupuesto vigente,
/// pero conserva su historial tal cual quedó.
class Budget {
  const Budget({
    required this.id,
    required this.name,
    required this.type,
    required this.limitAmount,
    required this.startDate,
    required this.endDate,
    required this.note,
    required this.notifyExceeded,
    required this.notifyNearLimit,
    required this.status,
    required this.categories,
    required this.createdAt,
    this.pausedAt,
    this.resumedAt,
  });

  final String id;
  final String name;
  final BudgetType type;
  final double limitAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String note;
  final bool notifyExceeded;
  final bool notifyNearLimit;
  final BudgetStatus status;
  final List<BudgetCategoryAllocation> categories;
  final DateTime createdAt;

  /// Marca de la última vez que se pausó — junto con [resumedAt]
  /// delimita la ventana "congelada" que [computeBudgetProgress]
  /// excluye del cálculo (los gastos hechos mientras estaba pausado
  /// nunca cuentan contra el presupuesto).
  final DateTime? pausedAt;

  /// Marca de la última vez que se reanudó tras estar pausado — nulo
  /// mientras sigue pausado (la ventana congelada sigue abierta).
  final DateTime? resumedAt;

  bool get isPastEnd => DateTime.now().isAfter(endDate);

  /// El presupuesto cuenta como "vigente" (elegible para ser EL activo)
  /// si no fue cancelado y todavía no pasó su fecha límite.
  bool get isCurrent => status != BudgetStatus.cancelled && !isPastEnd;

  int get daysLeft => endDate.difference(DateTime.now()).inDays.clamp(0, 1 << 30);

  factory Budget.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Budget(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: BudgetType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => BudgetType.general,
      ),
      limitAmount: (data['limitAmount'] as num?)?.toDouble() ?? 0,
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ??
          DateTime.now().add(const Duration(days: 30)),
      note: data['note'] as String? ?? '',
      notifyExceeded: data['notifyExceeded'] as bool? ?? true,
      notifyNearLimit: data['notifyNearLimit'] as bool? ?? true,
      status: BudgetStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => BudgetStatus.active,
      ),
      categories: (data['categories'] as List<dynamic>? ?? [])
          .map((c) => BudgetCategoryAllocation.fromMap(c as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pausedAt: (data['pausedAt'] as Timestamp?)?.toDate(),
      resumedAt: (data['resumedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type.name,
      'limitAmount': limitAmount,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'note': note,
      'notifyExceeded': notifyExceeded,
      'notifyNearLimit': notifyNearLimit,
      'status': status.name,
      'categories': categories.map((c) => c.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      if (pausedAt != null) 'pausedAt': Timestamp.fromDate(pausedAt!),
      if (resumedAt != null) 'resumedAt': Timestamp.fromDate(resumedAt!),
    };
  }
}
