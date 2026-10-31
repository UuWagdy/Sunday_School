/// Reconciles a sorted, loaded prefix. Unknown changed rows beyond its boundary
/// stay on later pages. Deleted/filtered rows leave a gap to fill with a tail
/// query; unchanged DTOs retain their identity.
List<T> mergeChangedPrefix<T>({
  required List<T> cached,
  required Iterable<T> changed,
  required Set<int> changedIds,
  required int Function(T) idOf,
  required int Function(T, T) compare,
  required bool hasMore,
}) {
  final boundary = cached.isEmpty ? null : cached.last;
  final result = cached
      .where((row) => !changedIds.contains(idOf(row)))
      .toList();
  result.addAll(
    changed.where(
      (row) => !hasMore || boundary == null || compare(row, boundary) <= 0,
    ),
  );
  result.sort(compare);
  return result;
}
