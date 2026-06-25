import '../../models/tile.dart';

class DragData {
  final Tile tile;
  final String source; // 'rack' or 'board'
  final int? fromMeldIdx;
  final int? fromTileIdx;

  DragData({
    required this.tile,
    required this.source,
    this.fromMeldIdx,
    this.fromTileIdx,
  });
}
