import 'dart:math';
import '../models/tile.dart';
import '../models/meld.dart';
import '../models/board.dart';
import 'ai_base.dart';
import 'ai_helper.dart';

class AIEasy extends AIBase {
  final Random _random = Random();

  @override
  MapEntry<Board, List<Tile>>? playTurn(
    Board currentBoard,
    List<Tile> hand,
    bool hasMadeInitialMeld,
  ) {
    // 20% chance to miss a move (simulating distractibility of an easy AI)
    if (_random.nextDouble() < 0.20) {
      return null;
    }

    // Find all combinations of valid disjoint melds that can be made from the hand
    final combinations = AIHelper.findDisjointMeldCombinations(hand);
    if (combinations.isEmpty) {
      return null;
    }

    if (!hasMadeInitialMeld) {
      // Must find a combination that has points >= 30
      final validOpenings = combinations.where((comb) {
        int sum = comb.fold(0, (s, meld) => s + meld.points);
        return sum >= 30;
      }).toList();

      if (validOpenings.isEmpty) {
        return null; // Cannot open
      }

      // Pick a random valid opening combination
      final chosenComb = validOpenings[_random.nextInt(validOpenings.length)];
      return _applyMeldsToBoard(currentBoard, hand, chosenComb);
    } else {
      // Already opened. Sort combinations by number of tiles played (more tiles = better)
      combinations.sort((a, b) {
        final tilesA = a.fold(0, (sum, m) => sum + m.tiles.length);
        final tilesB = b.fold(0, (sum, m) => sum + m.tiles.length);
        return tilesB.compareTo(tilesA); // descending
      });

      final chosenComb = combinations.first;

      // Make sure it plays at least one tile
      if (chosenComb.isEmpty) return null;

      return _applyMeldsToBoard(currentBoard, hand, chosenComb);
    }
  }

  MapEntry<Board, List<Tile>> _applyMeldsToBoard(
    Board currentBoard,
    List<Tile> hand,
    List<Meld> newMelds,
  ) {
    // Add new melds to board
    final updatedMelds = List<Meld>.from(currentBoard.melds)..addAll(newMelds);
    final nextBoard = currentBoard.copyWith(melds: updatedMelds);

    // Remove played tiles from hand
    final playedIds = newMelds.expand((m) => m.tiles).map((t) => t.id).toSet();
    final nextHand = hand.where((tile) => !playedIds.contains(tile.id)).toList();

    return MapEntry(nextBoard, nextHand);
  }
}
