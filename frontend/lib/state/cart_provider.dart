import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart_item_model.dart';
import '../services/api_service.dart';

/// Backs the "Buy Materials" one-click cart (Feature 8).
class CartController extends StateNotifier<AsyncValue<CartSummaryModel>> {
  CartController() : super(const AsyncValue.loading()) {
    load();
  }

  final _api = ApiService.instance;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.getCart());
  }

  Future<void> addDesign(String designId) async {
    state = await AsyncValue.guard(() => _api.addDesignToCart(designId));
  }

  Future<void> removeItem(String itemId) async {
    state = await AsyncValue.guard(() => _api.removeCartItem(itemId));
  }
}

final cartProvider = StateNotifierProvider.autoDispose<CartController,
    AsyncValue<CartSummaryModel>>(
  (ref) => CartController(),
);
