import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/design_model.dart';
import '../services/api_service.dart';

/// Loads + mutates the user's design history (Feature 10) and favourites.
class HistoryController extends StateNotifier<AsyncValue<List<DesignModel>>> {
  HistoryController() : super(const AsyncValue.loading()) {
    load();
  }

  final _api = ApiService.instance;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _api.listDesigns());
  }

  Future<void> toggleFavourite(String designId) async {
    final current = state.value;
    if (current == null) return;
    final target = current.firstWhere((d) => d.id == designId);
    final updated =
        await _api.updateDesign(designId, isFavourite: !target.isFavourite);
    state = AsyncValue.data([
      for (final d in current)
        if (d.id == designId) updated else d,
    ]);
  }

  Future<void> deleteDesign(String designId) async {
    final current = state.value;
    if (current == null) return;
    await _api.deleteDesign(designId);
    state = AsyncValue.data(current.where((d) => d.id != designId).toList());
  }
}

final historyProvider = StateNotifierProvider.autoDispose<HistoryController,
    AsyncValue<List<DesignModel>>>(
  (ref) => HistoryController(),
);

final favouriteDesignsProvider = Provider.autoDispose<List<DesignModel>>((ref) {
  final history = ref.watch(historyProvider).value ?? [];
  return history.where((d) => d.isFavourite).toList();
});
