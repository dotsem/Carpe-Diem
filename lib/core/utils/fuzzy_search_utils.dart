import 'package:fuzzy/fuzzy.dart';

class FuzzySearchUtils {
  /// Fuzzy searches [items] using the [query].
  /// [itemToString] is used to extract the searchable text from each item.
  /// Returns a list of matched items sorted by relevance.
  static List<T> search<T>({
    required String query,
    required List<T> items,
    required String Function(T) itemToString,
    double threshold = 0.4,
  }) {
    if (query.trim().isEmpty) return items;

    final fuse = Fuzzy<T>(
      items,
      options: FuzzyOptions(
        threshold: threshold,
        keys: [WeightedKey(name: 'search_key', getter: (dynamic item) => itemToString(item as T), weight: 1)],
      ),
    );

    final result = fuse.search(query);
    return result.map((r) => r.item).toList();
  }
}
