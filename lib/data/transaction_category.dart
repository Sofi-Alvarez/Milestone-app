import 'package:flutter/material.dart';

enum TransactionType { income, expense }

class TransactionCategory {
  const TransactionCategory({
    required this.id,
    required this.label,
    required this.icon,
  });

  final String id;
  final String label;
  final IconData icon;
}

const expenseCategories = <TransactionCategory>[
  TransactionCategory(
    id: 'restaurantes',
    label: 'Restaurantes y bares',
    icon: Icons.restaurant_outlined,
  ),
  TransactionCategory(
    id: 'comestibles',
    label: 'Comestibles',
    icon: Icons.shopping_basket_outlined,
  ),
  TransactionCategory(
    id: 'transporte',
    label: 'Transporte',
    icon: Icons.directions_bus_outlined,
  ),
  TransactionCategory(id: 'hogar', label: 'Hogar', icon: Icons.home_outlined),
  TransactionCategory(
    id: 'facturas',
    label: 'Facturas y servicios',
    icon: Icons.receipt_long_outlined,
  ),
  TransactionCategory(
    id: 'entretenimiento',
    label: 'Entretenimiento',
    icon: Icons.movie_outlined,
  ),
  TransactionCategory(
    id: 'vehiculo',
    label: 'Vehículo',
    icon: Icons.directions_car_outlined,
  ),
  TransactionCategory(
    id: 'viajes',
    label: 'Viajes',
    icon: Icons.flight_outlined,
  ),
  TransactionCategory(
    id: 'familia',
    label: 'Familia y niños',
    icon: Icons.family_restroom_outlined,
  ),
  TransactionCategory(
    id: 'salud',
    label: 'Salud',
    icon: Icons.medical_services_outlined,
  ),
  TransactionCategory(
    id: 'educacion',
    label: 'Educación',
    icon: Icons.school_outlined,
  ),
  TransactionCategory(
    id: 'compras',
    label: 'Compras',
    icon: Icons.shopping_cart_outlined,
  ),
  TransactionCategory(
    id: 'deportes',
    label: 'Deportes',
    icon: Icons.sports_soccer_outlined,
  ),
  TransactionCategory(
    id: 'belleza',
    label: 'Belleza',
    icon: Icons.spa_outlined,
  ),
  TransactionCategory(
    id: 'trabajo',
    label: 'Trabajo',
    icon: Icons.work_outline,
  ),
  TransactionCategory(
    id: 'otros_gasto',
    label: 'Otros',
    icon: Icons.more_horiz,
  ),
];

const incomeCategories = <TransactionCategory>[
  TransactionCategory(
    id: 'salario',
    label: 'Salario',
    icon: Icons.payments_outlined,
  ),
  TransactionCategory(
    id: 'negocios',
    label: 'Negocios / Freelance',
    icon: Icons.business_center_outlined,
  ),
  TransactionCategory(
    id: 'regalos_ingreso',
    label: 'Regalos',
    icon: Icons.card_giftcard_outlined,
  ),
  TransactionCategory(
    id: 'extra',
    label: 'Ingresos extra / Varios',
    icon: Icons.add_circle_outline,
  ),
  TransactionCategory(
    id: 'prestamo',
    label: 'Préstamo recibido',
    icon: Icons.account_balance_outlined,
  ),
  TransactionCategory(
    id: 'reembolso',
    label: 'Reembolso / Pago',
    icon: Icons.replay_outlined,
  ),
  TransactionCategory(
    id: 'subsidios',
    label: 'Subsidios / Beneficios',
    icon: Icons.volunteer_activism_outlined,
  ),
  TransactionCategory(
    id: 'otros_ingreso',
    label: 'Otros',
    icon: Icons.more_horiz,
  ),
];

List<TransactionCategory> categoriesFor(TransactionType type) =>
    type == TransactionType.expense ? expenseCategories : incomeCategories;

TransactionCategory? findCategory(String id) {
  for (final c in [...expenseCategories, ...incomeCategories]) {
    if (c.id == id) return c;
  }
  return null;
}
