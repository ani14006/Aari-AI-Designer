import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../state/cart_provider.dart';
import '../../widgets/common/luxury_card.dart';
import '../../widgets/common/responsive_page.dart';
import '../../widgets/common/retryable_error.dart';
import '../../widgets/result/shopping_list_tile.dart' show formatCurrency;

/// Feature 8 destination: everything added via "Buy Materials" across all designs.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: Breakpoints.formMaxWidth,
          child: cart.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => RetryableError(
              message: 'Could not load cart.',
              onRetry: () => ref.read(cartProvider.notifier).load(),
            ),
            data: (summary) {
              if (summary.items.isEmpty) {
                return const Center(child: Text('Your cart is empty.'));
              }
              return Column(
                children: [
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: summary.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final item = summary.items[index];
                        return LuxuryCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(item.name,
                                style: Theme.of(context).textTheme.titleSmall),
                            subtitle: Text(
                                '${item.quantity} · ${formatCurrency(item.unitPrice)} each'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formatCurrency(item.totalPrice),
                                    style:
                                        Theme.of(context).textTheme.titleSmall),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded,
                                      color: AppColors.error),
                                  onPressed: () => ref
                                      .read(cartProvider.notifier)
                                      .removeItem(item.id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppTheme.radiusLarge)),
                      boxShadow: AppTheme.softShadow(context, strength: 1.2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          formatCurrency(summary.totalCost),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(color: AppColors.roseGold),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
