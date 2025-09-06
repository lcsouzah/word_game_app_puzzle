class GridPosition {
  final int row;
  final int col;

  const GridPosition(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      other is GridPosition && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);
}

class SerpuzzleGrid {
  final int rows;
  final int cols;
  late final List<String> _tiles;

  SerpuzzleGrid({required this.rows, required this.cols}) {
    _tiles = List.filled(rows * cols, '');
  }

  int get length => _tiles.length;

  int _index(GridPosition position) => position.row * cols + position.col;

  bool inBounds(GridPosition position) {
    return position.row >= 0 &&
        position.row < rows &&
        position.col >= 0 &&
        position.col < cols;
  }

  void placeLetter(GridPosition position, String letter) {
    if (!inBounds(position)) return;
    _tiles[_index(position)] = letter;
  }

  String letterAt(GridPosition position) {
    if (!inBounds(position)) return '';
    return _tiles[_index(position)];
  }

  GridPosition positionOfIndex(int index) {
    return GridPosition(index ~/ cols, index % cols);
  }

  int indexOfPosition(GridPosition position) {
    return _index(position);
  }
}