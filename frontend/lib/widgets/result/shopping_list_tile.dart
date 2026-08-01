import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/shopping_item.dart';

final _currencyFormat =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

IconData _iconForCategory(String category) {
  switch (category) {
    case 'bead':
      return Icons.grain_rounded;
    case 'tool':
      return Icons.build_circle_outlined;
    case 'fabric':
      return Icons.checkroom_rounded;
    default:
      return Icons.shopping_bag_outlined;
  }
}

/// One row in the "Material List" on the Result screen.
class ShoppingListTile extends StatelessWidget {
  final ShoppingItem item;

  const ShoppingListTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            height: 38,
            width: 38,
            decoration: BoxDecoration(
                color: AppColors.champagne,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(_iconForCategory(item.category),
                size: 19, color: AppColors.antiqueGold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.bodyLarge),
                Text(item.quantity,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(
            _currencyFormat.format(item.totalPrice),
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

String formatCurrency(double amount) => _currencyFormat.format(amount);
