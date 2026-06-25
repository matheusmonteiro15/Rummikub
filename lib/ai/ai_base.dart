import '../models/tile.dart';
import '../models/board.dart';

abstract class AIBase {
  // Returns MapEntry(newBoard, newHand) if a play was made, or null if bot must draw.
  MapEntry<Board, List<Tile>>? playTurn(
    Board currentBoard,
    List<Tile> hand,
    bool hasMadeInitialMeld,
  );
}
