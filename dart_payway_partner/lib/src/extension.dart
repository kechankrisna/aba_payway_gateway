extension PaywayPartnerStringExt on String {
  List<String> splitByLength(int length, {bool ignoreEmpty = false}) {
    List<String> pieces = [];

    for (int i = 0; i < this.length; i += length) {
      int offset = i + length;
      String piece = substring(i, offset >= this.length ? this.length : offset);
      
      if (ignoreEmpty) {
        piece = piece.replaceAll(RegExp(r'\s+'), '');
      }

      pieces.add(piece);
    }
    return pieces;
  }
}

extension PaywayPartnerIntExt on List<int> {
  List<List<int>> splitByLength(int length, {bool ignoreEmpty = false}) {
    List<List<int>> pieces = [];

    for (int i = 0; i < this.length; i += length) {
      int offset = i + length;

      List<int> piece = sublist(i, offset >= this.length ? this.length : offset);

      pieces.add(piece);
    }
    return pieces;
  }
}
