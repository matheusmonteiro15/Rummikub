import 'dart:math';
import '../models/tile.dart';
import '../models/meld.dart';
import '../models/board.dart';
import '../models/player.dart';

class GameController {
  List<Player> players = [];
  int currentPlayerIndex = 0;
  Board board = Board.empty();
  List<Tile> pool = [];
  bool isGameOver = false;
  Player? winner;
  List<String> gameLog = [];
  int consecutivePasses = 0;

  // Temporary turn state for active player
  List<Tile> turnHand = [];
  Board turnBoard = Board.empty();

  // Snapshot at start of turn (for Undo / Revert)
  List<Tile> initialHand = [];
  Board initialBoard = Board.empty();

  Player get currentPlayer => players[currentPlayerIndex];

  void initGame(List<Player> initialPlayers) {
    players = List.from(initialPlayers);
    board = Board.empty();
    gameLog = [];
    isGameOver = false;
    winner = null;
    consecutivePasses = 0;

    // Create 106 tiles
    pool = [];
    int idCounter = 1;

    // 104 normal tiles: 1-13, 4 colors, 2 of each
    for (var color in TileColor.values) {
      for (int num = 1; num <= 13; num++) {
        pool.add(Tile.normal('t_${color.name}_${num}_a', num, color));
        pool.add(Tile.normal('t_${color.name}_${num}_b', num, color));
      }
    }

    // 2 Jokers
    pool.add(Tile.joker('joker_1'));
    pool.add(Tile.joker('joker_2'));

    // Shuffle pool
    pool.shuffle(Random());

    // Deal 14 tiles to each player
    for (int i = 0; i < players.length; i++) {
      final hand = <Tile>[];
      for (int k = 0; k < 14; k++) {
        if (pool.isNotEmpty) {
          hand.add(pool.removeLast());
        }
      }
      players[i] = players[i].copyWith(
        tiles: hand,
        hasMadeInitialMeld: false,
      );
    }

    currentPlayerIndex = 0;
    _log('O jogo começou! ${players.length} jogadores na mesa.');
    startTurn();
  }

  void startTurn() {
    initialHand = List.from(currentPlayer.tiles);
    initialBoard = board;
    turnHand = List.from(currentPlayer.tiles);
    turnBoard = board;
    _log('Turno de ${currentPlayer.name}.');
  }

  void _log(String message) {
    gameLog.add('[${DateTime.now().toLocal().toString().substring(11, 16)}] $message');
  }

  // --- Board Manipulation Actions ---

  // Sort current player's hand by runs (color then number)
  void sortHandByRuns() {
    final sorted = List<Tile>.from(turnHand);
    sorted.sort((a, b) {
      if (a.isJoker && b.isJoker) return 0;
      if (a.isJoker) return 1; // Jokers at the end
      if (b.isJoker) return -1;

      final colorComp = a.color!.index.compareTo(b.color!.index);
      if (colorComp != 0) return colorComp;
      return a.number!.compareTo(b.number!);
    });
    turnHand = sorted;
  }

  // Sort current player's hand by groups (number then color)
  void sortHandByGroups() {
    final sorted = List<Tile>.from(turnHand);
    sorted.sort((a, b) {
      if (a.isJoker && b.isJoker) return 0;
      if (a.isJoker) return 1;
      if (b.isJoker) return -1;

      final numComp = a.number!.compareTo(b.number!);
      if (numComp != 0) return numComp;
      return a.color!.index.compareTo(b.color!.index);
    });
    turnHand = sorted;
  }

  // Move tile from player's hand to board
  // If meldIndex is -1, create a new meld
  // If positionIndex is -1, append to the meld
  bool moveTileToBoard(Tile tile, int meldIndex, int positionIndex) {
    if (!turnHand.contains(tile)) return false;

    final updatedMelds = List<Meld>.from(turnBoard.melds);

    if (meldIndex == -1) {
      // Create new meld
      updatedMelds.add(Meld([tile]));
    } else {
      // Add to existing meld
      final targetMeld = updatedMelds[meldIndex];
      final newTiles = List<Tile>.from(targetMeld.tiles);
      if (positionIndex == -1 || positionIndex >= newTiles.length) {
        newTiles.add(tile);
      } else {
        newTiles.insert(positionIndex, tile);
      }
      updatedMelds[meldIndex] = Meld(newTiles);
    }

    turnHand.remove(tile);
    turnBoard = turnBoard.copyWith(melds: updatedMelds);
    return true;
  }

  // Move a tile from one meld to another (or create a new one)
  bool moveTileWithinBoard(int fromMeldIdx, int fromTileIdx, int toMeldIdx, int toTileIdx) {
    if (fromMeldIdx < 0 || fromMeldIdx >= turnBoard.melds.length) return false;

    final sourceMeld = turnBoard.melds[fromMeldIdx];
    if (fromTileIdx < 0 || fromTileIdx >= sourceMeld.tiles.length) return false;

    final tile = sourceMeld.tiles[fromTileIdx];
    final updatedMelds = List<Meld>.from(turnBoard.melds);

    // Remove tile from source meld
    final sourceTiles = List<Tile>.from(sourceMeld.tiles);
    sourceTiles.removeAt(fromTileIdx);

    if (sourceTiles.isEmpty) {
      // If meld is empty, remove it and adjust target index if it shifts
      updatedMelds.removeAt(fromMeldIdx);
      if (toMeldIdx > fromMeldIdx) {
        toMeldIdx--;
      }
    } else {
      updatedMelds[fromMeldIdx] = Meld(sourceTiles);
    }

    // Insert tile to destination
    if (toMeldIdx == -1) {
      updatedMelds.add(Meld([tile]));
    } else {
      final destMeld = updatedMelds[toMeldIdx];
      final destTiles = List<Tile>.from(destMeld.tiles);
      if (toTileIdx == -1 || toTileIdx >= destTiles.length) {
        destTiles.add(tile);
      } else {
        destTiles.insert(toTileIdx, tile);
      }
      updatedMelds[toMeldIdx] = Meld(destTiles);
    }

    turnBoard = turnBoard.copyWith(melds: updatedMelds);
    return true;
  }

  // Move a tile back to player's hand (only if it was originally in their hand this turn)
  bool moveTileToHand(Tile tile, int fromMeldIdx, int fromTileIdx) {
    if (!initialHand.contains(tile)) return false; // Cannot take old tiles from board to hand

    if (fromMeldIdx < 0 || fromMeldIdx >= turnBoard.melds.length) return false;
    final meld = turnBoard.melds[fromMeldIdx];
    if (fromTileIdx < 0 || fromTileIdx >= meld.tiles.length) return false;

    final updatedMelds = List<Meld>.from(turnBoard.melds);
    final meldTiles = List<Tile>.from(meld.tiles);
    meldTiles.removeAt(fromTileIdx);

    if (meldTiles.isEmpty) {
      updatedMelds.removeAt(fromMeldIdx);
    } else {
      updatedMelds[fromMeldIdx] = Meld(meldTiles);
    }

    turnHand.add(tile);
    turnBoard = turnBoard.copyWith(melds: updatedMelds);
    return true;
  }

  // Split a meld at a specific index
  bool splitMeld(int meldIdx, int splitIdx) {
    if (meldIdx < 0 || meldIdx >= turnBoard.melds.length) return false;
    final meld = turnBoard.melds[meldIdx];
    if (splitIdx <= 0 || splitIdx >= meld.tiles.length) return false;

    final updatedMelds = List<Meld>.from(turnBoard.melds);
    final leftTiles = meld.tiles.sublist(0, splitIdx);
    final rightTiles = meld.tiles.sublist(splitIdx);

    updatedMelds[meldIdx] = Meld(leftTiles);
    updatedMelds.insert(meldIdx + 1, Meld(rightTiles));

    turnBoard = turnBoard.copyWith(melds: updatedMelds);
    return true;
  }

  // Revert all turn actions
  void undoChanges() {
    turnBoard = initialBoard;
    turnHand = List.from(initialHand);
  }

  // Draw a tile: Reverts all temporary board changes, draws a tile, and passes turn
  void drawTile() {
    undoChanges();

    if (pool.isNotEmpty) {
      final drawn = pool.removeLast();
      final newTiles = List<Tile>.from(currentPlayer.tiles)..add(drawn);
      players[currentPlayerIndex] = currentPlayer.copyWith(
        tiles: newTiles,
      );
      _log('${currentPlayer.name} comprou uma peça.');
    } else {
      _log('${currentPlayer.name} tentou comprar, mas a pilha de compras está vazia.');
    }

    consecutivePasses++;
    if (consecutivePasses >= players.length) {
      endGameByDeadlock();
      return;
    }

    nextTurn();
  }

  // --- Verification and Turn End ---

  // Main turn validation
  String? validateTurn() {
    // 1. Board validity: All groups/runs on board must be valid
    if (!turnBoard.isValid) {
      return 'Existem combinações inválidas ou incompletas na mesa (mínimo de 3 peças por grupo/sequência).';
    }

    // 2. Play validation: Must have played at least one tile
    if (turnHand.length == initialHand.length) {
      return 'Você precisa jogar pelo menos uma peça ou comprar uma nova.';
    }

    // 3. Prevent taking board tiles to hand (built-in, but double check)
    for (var tile in turnHand) {
      if (!initialHand.contains(tile)) {
        return 'Erro: Você não pode pegar peças que já estavam na mesa para a sua mão.';
      }
    }

    // 4. Initial Meld validation (30 points rule)
    if (!currentPlayer.hasMadeInitialMeld) {
      // Identify new melds made purely from the hand
      final List<Meld> newMelds = [];
      for (var meld in turnBoard.melds) {
        // A meld is "new" if it was not in initialBoard
        final wasInInitial = initialBoard.melds.any((oldMeld) {
          if (oldMeld.tiles.length != meld.tiles.length) return false;
          for (int i = 0; i < meld.tiles.length; i++) {
            if (oldMeld.tiles[i].id != meld.tiles[i].id) return false;
          }
          return true;
        });

        if (!wasInInitial) {
          // Verify it consists only of tiles from the initial hand (no table manipulation)
          final usesOnlyHandTiles = meld.tiles.every((tile) => initialHand.contains(tile));
          if (!usesOnlyHandTiles) {
            return 'Abertura Inicial inválida: Você não pode usar peças da mesa na sua primeira jogada.';
          }
          newMelds.add(meld);
        }
      }

      int totalPoints = newMelds.fold(0, (sum, meld) => sum + meld.points);
      if (totalPoints < 30) {
        return 'Abertura Inicial inválida: Suas novas combinações somam apenas $totalPoints pontos (mínimo 30).';
      }
    }

    // 5. Traditional Joker Rule Validation (Rigid)
    // Find all Jokers on the board in initialBoard and check their state in turnBoard
    final initialJokers = initialBoard.allTiles.where((t) => t.isJoker).toList();
    for (var joker in initialJokers) {
      // Find what it represented in initialBoard
      Meld? initialMeldOfJoker;
      int jokerIdxInInitialMeld = -1;
      for (var meld in initialBoard.melds) {
        jokerIdxInInitialMeld = meld.tiles.indexOf(joker);
        if (jokerIdxInInitialMeld != -1) {
          initialMeldOfJoker = meld;
          break;
        }
      }

      if (initialMeldOfJoker == null) continue;

      final jokerRep = initialMeldOfJoker.getJokerRepresentations()[jokerIdxInInitialMeld];
      if (jokerRep == null) continue;

      // Check if the Joker was replaced at its original spot by the matching tile
      // We look at the board to see if there is a meld containing the original tiles (except the joker is replaced by the actual tile)
      // Or simply: check if the exact tile J represented (jokerRep) is now in the board, and the Joker is elsewhere.
      // If the Joker is in a different position:
      bool isJokerMoved = true;
      for (var meld in turnBoard.melds) {
        final idx = meld.tiles.indexOf(joker);
        if (idx != -1) {
          // If the Joker is still in the same meld at the same position with same neighbors, it wasn't replaced/retrieved
          // We can check if the meld has the same tile IDs
          final wasInInitial = initialBoard.melds.any((oldMeld) {
            if (oldMeld.tiles.length != meld.tiles.length) return false;
            final oldIdx = oldMeld.tiles.indexOf(joker);
            if (oldIdx != idx) return false;
            // check neighbors
            for (int i = 0; i < meld.tiles.length; i++) {
              if (oldMeld.tiles[i].id != meld.tiles[i].id) return false;
            }
            return true;
          });
          if (wasInInitial) {
            isJokerMoved = false;
          }
          break;
        }
      }

      if (isJokerMoved) {
        // The Joker was moved/retrieved.
        // Rule: The player must have replaced the Joker with the exact tile from their hand.
        // So the exact tile (number, color) must have been in initialHand.
        // And that exact tile must now be on the board (replacing the Joker).
        final hasReplacingTile = initialHand.any((tile) =>
            !tile.isJoker &&
            tile.number == jokerRep.number &&
            tile.color == jokerRep.color);

        if (!hasReplacingTile) {
          return 'Regra do Coringa: Você só pode mover ou retirar o Coringa se substituí-lo pela peça correspondente (${jokerRep.toString()}) de sua mão.';
        }

        // Rule: The retrieved Joker must be played in a NEW meld with at least 2 tiles from the hand
        // Find the meld containing the Joker in turnBoard
        Meld? newMeldOfJoker;
        for (var meld in turnBoard.melds) {
          if (meld.tiles.contains(joker)) {
            newMeldOfJoker = meld;
            break;
          }
        }

        if (newMeldOfJoker == null) {
          return 'Regra do Coringa: O Coringa resgatado deve ser recolocado na mesa.';
        }

        // Was it a new meld? (A meld not in initialBoard)
        final isNewMeld = !initialBoard.melds.any((oldMeld) {
          if (oldMeld.tiles.length != newMeldOfJoker!.tiles.length) return false;
          for (int i = 0; i < newMeldOfJoker.tiles.length; i++) {
            if (oldMeld.tiles[i].id != newMeldOfJoker.tiles[i].id) return false;
          }
          return true;
        });

        if (!isNewMeld) {
          return 'Regra do Coringa: O Coringa resgatado deve ser jogado em uma NOVA combinação (não em uma existente).';
        }

        // Does it contain at least 2 other tiles from hand?
        final handTilesInMeldCount = newMeldOfJoker.tiles.where((tile) {
          return tile.id != joker.id && initialHand.contains(tile);
        }).length;

        if (handTilesInMeldCount < 2) {
          return 'Regra do Coringa: O Coringa resgatado deve ser jogado em uma nova combinação junto com pelo menos 2 peças de sua própria mão.';
        }
      }
    }

    return null; // Valid turn!
  }

  // End turn, commit state, and proceed to next player
  bool commitTurn() {
    final validationError = validateTurn();
    if (validationError != null) {
      return false; // Cannot end turn, invalid state
    }

    // Commit turn hand & board
    final playedTilesCount = initialHand.length - turnHand.length;
    board = turnBoard;
    players[currentPlayerIndex] = currentPlayer.copyWith(
      tiles: List.from(turnHand),
      hasMadeInitialMeld: true, // If they passed validation, they have now made initial meld
    );

    _log('${currentPlayer.name} finalizou o turno jogando $playedTilesCount peça(s).');
    consecutivePasses = 0;

    // Check Win Condition
    if (currentPlayer.tiles.isEmpty) {
      isGameOver = true;
      winner = currentPlayer;
      _log('${currentPlayer.name} venceu o jogo esvaziando seu suporte!');
      return true;
    }

    nextTurn();
    return true;
  }

  void nextTurn() {
    if (isGameOver) return;

    currentPlayerIndex = (currentPlayerIndex + 1) % players.length;
    startTurn();
  }

  void endGameByDeadlock() {
    isGameOver = true;
    _log('Fim de jogo por bloqueio! O monte está vazio e todos os jogadores passaram.');
    
    Player? bestPlayer;
    int minScore = 999999;
    
    for (var player in players) {
      int score = player.tiles.fold(0, (sum, tile) => sum + (tile.isJoker ? 30 : tile.number!));
      if (score < minScore) {
        minScore = score;
        bestPlayer = player;
      }
    }
    
    winner = bestPlayer;
    if (winner != null) {
      _log('Vencedor por menor pontuação no suporte: ${winner!.name} com $minScore ponto(s).');
    }
  }
}
