import 'package:flutter/material.dart';

import '../../data/transaction_category.dart';
import '../../theme/app_theme.dart';

Future<TransactionCategory?> showCategoryPicker(
  BuildContext context, {
  required TransactionType type,
}) {
  return showModalBottomSheet<TransactionCategory>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CategoryPickerSheet(type: type),
  );
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.type});

  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = categoriesFor(type);

    return Container(
      decoration: BoxDecoration(
        color: cardColor(theme),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(HitoRadius.lg),
          topRight: Radius.circular(HitoRadius.lg),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        HitoSpacing.lg,
        HitoSpacing.sm,
        HitoSpacing.lg,
        HitoSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(HitoRadius.sm),
                ),
              ),
            ),
            const SizedBox(height: HitoSpacing.md),
            Text(
              type == TransactionType.income ? 'Categoría de ingreso' : 'Categoría de gasto',
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: HitoSpacing.md),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.5,
              ),
              child: SingleChildScrollView(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: HitoSpacing.sm,
                    crossAxisSpacing: HitoSpacing.sm,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(HitoRadius.md),
                      onTap: () => Navigator.of(context).pop(category),
                      child: Column(
                        // Alineado arriba — así el ícono queda a la misma
                        // altura sin importar si el label ocupa 1 o 2
                        // líneas (centrar el grupo lo desplazaba).
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: theme.colorScheme.tertiaryContainer,
                            child: Icon(
                              category.icon,
                              color: theme.colorScheme.onTertiaryContainer,
                            ),
                          ),
                          const SizedBox(height: HitoSpacing.xs),
                          Text(
                            category.label,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
