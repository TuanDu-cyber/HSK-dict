class PaginationWindow {
  const PaginationWindow({
    required this.startIndex,
    required this.endIndex,
    required this.canGoPreviousGroup,
    required this.canGoNextGroup,
  });

  final int startIndex;
  final int endIndex;
  final bool canGoPreviousGroup;
  final bool canGoNextGroup;

  Iterable<int> get indexes sync* {
    for (var index = startIndex; index <= endIndex; index++) {
      yield index;
    }
  }
}

PaginationWindow buildPaginationWindow({
  required int currentIndex,
  required int total,
  int groupSize = 5,
}) {
  if (total <= 0) {
    return const PaginationWindow(
      startIndex: 0,
      endIndex: -1,
      canGoPreviousGroup: false,
      canGoNextGroup: false,
    );
  }

  final safeCurrentIndex = currentIndex.clamp(0, total - 1);
  final currentPage = safeCurrentIndex + 1;
  final groupStartPage = ((currentPage - 1) ~/ groupSize) * groupSize + 1;
  final groupEndPage = (groupStartPage + groupSize - 1).clamp(1, total);

  return PaginationWindow(
    startIndex: groupStartPage - 1,
    endIndex: groupEndPage - 1,
    canGoPreviousGroup: groupStartPage > 1,
    canGoNextGroup: groupEndPage < total,
  );
}
