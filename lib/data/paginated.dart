/// Mirrors `BasePaginatedResponse` in
/// feishin/src/shared/types/domain-types.ts.
class PaginatedList<T> {
  const PaginatedList({
    required this.items,
    required this.startIndex,
    required this.totalRecordCount,
  });

  final List<T> items;
  final int startIndex;
  final int totalRecordCount;
}
