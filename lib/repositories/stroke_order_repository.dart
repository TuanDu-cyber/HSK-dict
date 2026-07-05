import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:stroke_order_animator/stroke_order_animator.dart';

final strokeOrderRepositoryProvider = Provider<StrokeOrderRepository>((ref) {
  final repository = StrokeOrderRepository();
  ref.onDispose(repository.dispose);
  return repository;
});

class StrokeOrderRepository {
  final http.Client _client = http.Client();
  final Map<String, String> _cache = {};

  Future<String> loadStrokeOrder(String character) async {
    final normalized = character.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(character, 'character', 'Character is empty');
    }

    final cached = _cache[normalized];
    if (cached != null) return cached;

    final rawData = await downloadStrokeOrder(normalized, _client);
    _cache[normalized] = rawData;
    return rawData;
  }

  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    _client.close();
  }
}
