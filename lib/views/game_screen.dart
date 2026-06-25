import 'package:flutter/material.dart';
import '../models/tile.dart';
import '../models/board.dart';
import '../models/player.dart';
import '../engine/game_controller.dart';
import '../ai/ai_base.dart';
import '../ai/ai_easy.dart';
import '../ai/ai_medium.dart';
import '../ai/ai_hard.dart';
import 'widgets/board_widget.dart';
import 'widgets/rack_widget.dart';
import 'widgets/drag_data.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final GameController _controller = GameController();
  bool _isPlaying = false;
  bool _isBotThinking = false;
  String _botThinkingName = '';
  
  // Game Setup parameters
  int _opponentCount = 2; // Default: 3 players total (You + 2 bots)
  final List<AILevel> _botDifficulties = [AILevel.easy, AILevel.medium, AILevel.hard];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1B3B2B), // Deep Forest Green
              Color(0xFF0F261C), // Deep Charcoal Green
            ],
          ),
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _isPlaying ? _buildGameBoard() : _buildGameSetup(),
          ),
        ),
      ),
    );
  }

  // --- Game Setup UI ---

  Widget _buildGameSetup() {
    return Center(
      key: const ValueKey('SetupKey'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(28.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white24, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                '🎲 RUMMIKUB',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Criado especialmente para o Papai',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const Divider(color: Colors.white24, height: 40),

              // Opponents Count
              const Text(
                'Quantidade de Oponentes (Bots)',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [1, 2, 3].map((count) {
                  final selected = _opponentCount == count;
                  return ChoiceChip(
                    label: Text(
                      '$count ${count == 1 ? "Bot" : "Bots"}',
                      style: TextStyle(
                        color: selected ? Colors.black87 : Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: selected,
                    selectedColor: const Color(0xFFFDD835),
                    backgroundColor: Colors.white12,
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _opponentCount = count;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // AI Difficulties
              const Text(
                'Dificuldade dos Oponentes',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _opponentCount,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Bot ${index + 1}',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        DropdownButton<AILevel>(
                          dropdownColor: const Color(0xFF1B3B2B),
                          value: _botDifficulties[index],
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                          items: AILevel.values.map((level) {
                            String name;
                            Color color;
                            switch (level) {
                              case AILevel.easy:
                                name = 'Fácil';
                                color = Colors.greenAccent;
                                break;
                              case AILevel.medium:
                                name = 'Médio';
                                color = Colors.orangeAccent;
                                break;
                              case AILevel.hard:
                                name = 'Difícil';
                                color = Colors.redAccent;
                                break;
                            }
                            return DropdownMenuItem(
                              value: level,
                              child: Text(
                                name,
                                style: TextStyle(color: color, fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _botDifficulties[index] = val;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFDD835), // Gold Accent
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                  ),
                  child: const Text(
                    'JOGAR AGORA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                  onPressed: () {
                    _startNewGame();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startNewGame() {
    final List<Player> newPlayers = [
      Player(id: 'human', name: 'Você (Papai)', isHuman: true),
    ];

    for (int i = 0; i < _opponentCount; i++) {
      final difficulty = _botDifficulties[i];
      String diffName = difficulty == AILevel.easy
          ? 'Fácil'
          : difficulty == AILevel.medium
              ? 'Médio'
              : 'Difícil';
      newPlayers.add(Player(
        id: 'bot_$i',
        name: 'Bot ${i + 1} ($diffName)',
        isHuman: false,
        aiLevel: difficulty,
      ));
    }

    setState(() {
      _controller.initGame(newPlayers);
      _isPlaying = true;
      _isBotThinking = false;
    });

    _triggerBotTurnIfNeeded();
  }

  // --- Game Play Board UI ---

  Widget _buildGameBoard() {
    final curPlayer = _controller.currentPlayer;

    return Stack(
      children: [
        Column(
          key: const ValueKey('BoardKey'),
          children: [
            // Top Player Status Bar
            _buildTopStatusBar(),

            // Board Area
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 8.0),
                child: BoardWidget(
                  board: _controller.turnBoard,
                  onTileDropped: (data, toMeldIdx, toTileIdx) {
                    setState(() {
                      if (data.source == 'rack') {
                        _controller.moveTileToBoard(data.tile, toMeldIdx, toTileIdx);
                      } else {
                        // source == board
                        _controller.moveTileWithinBoard(
                          data.fromMeldIdx!,
                          data.fromTileIdx!,
                          toMeldIdx,
                          toTileIdx,
                        );
                      }
                    });
                  },
                  onSplitMeld: (meldIdx, splitIdx) {
                    setState(() {
                      _controller.splitMeld(meldIdx, splitIdx);
                    });
                  },
                ),
              ),
            ),

            // Turn Status / Error Overlay Indicator
            if (_isBotThinking)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                width: double.infinity,
                color: Colors.orange.withOpacity(0.25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$_botThinkingName está pensando...',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            // Controls Area (Only visible when it is human's turn)
            if (curPlayer.isHuman && !_isBotThinking) _buildTurnControls(),

            // Rack Area
            RackWidget(
              tiles: _controller.turnHand,
              onSortByRuns: () {
                setState(() {
                  _controller.sortHandByRuns();
                });
              },
              onSortByGroups: () {
                setState(() {
                  _controller.sortHandByGroups();
                });
              },
              onReturnTileToHand: (data) {
                setState(() {
                  _controller.moveTileToHand(
                    data.tile,
                    data.fromMeldIdx!,
                    data.fromTileIdx!,
                  );
                });
              },
            ),
          ],
        ),
        if (_controller.isGameOver) _buildGameOverOverlay(),
      ],
    );
  }

  Widget _buildGameOverOverlay() {
    final winnerName = _controller.winner?.name ?? 'Empate';
    final isHumanWinner = _controller.winner?.isHuman == true;

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F261C),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHumanWinner ? const Color(0xFFFDD835) : Colors.redAccent.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isHumanWinner ? '🏆 PARABÉNS!' : 'FIM DE JOGO 🎲',
                  style: TextStyle(
                    color: isHumanWinner ? const Color(0xFFFDD835) : Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  isHumanWinner 
                      ? 'Você venceu a partida!' 
                      : _controller.winner == null 
                          ? 'O jogo terminou empatado!' 
                          : '${_controller.winner!.name} venceu o jogo.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                if (_controller.winner != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Vencedor: $winnerName',
                    style: const TextStyle(
                      color: Color(0xFFFDD835),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
                const Divider(color: Colors.white24, height: 32),
                const Text(
                  'Pontos restantes nos suportes:',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._controller.players.map((p) {
                  final pts = p.tiles.fold(0, (sum, tile) => sum + (tile.isJoker ? 30 : tile.number!));
                  final isThisWinner = _controller.winner?.id == p.id;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isThisWinner ? Colors.white.withOpacity(0.08) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: isThisWinner ? Border.all(color: const Color(0xFFFDD835).withOpacity(0.5)) : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          p.name, 
                          style: TextStyle(
                            color: isThisWinner ? const Color(0xFFFDD835) : Colors.white70, 
                            fontWeight: isThisWinner ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14
                          )
                        ),
                        Text(
                          '$pts pts (${p.tiles.length} peças)', 
                          style: TextStyle(
                            color: isThisWinner ? const Color(0xFFFDD835) : Colors.white70,
                            fontWeight: isThisWinner ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14
                          )
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFDD835),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('VOLTAR AO MENU', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      setState(() {
                        _isPlaying = false;
                      });
                    },
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopStatusBar() {
    return Container(
      color: Colors.black26,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Players list
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _controller.players.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final player = entry.value;
                  final isCurrent = _controller.currentPlayerIndex == idx;

                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? const Color(0xFFFDD835).withOpacity(0.2)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent ? const Color(0xFFFDD835) : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isCurrent)
                          const Padding(
                            padding: EdgeInsets.only(right: 4.0),
                            child: Icon(Icons.play_arrow, size: 12, color: Color(0xFFFDD835)),
                          ),
                        Text(
                          player.name,
                          style: TextStyle(
                            color: isCurrent ? const Color(0xFFFDD835) : Colors.white70,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.black38,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${player.tiles.length}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // Right: Log Button / Info Button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white70, size: 20),
                tooltip: 'Histórico',
                onPressed: _showGameLogsDialog,
              ),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.white70, size: 20),
                tooltip: 'Regras',
                onPressed: _showRulesDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTurnControls() {
    return Container(
      color: const Color(0xFF1E120A), // Matches wood bottom rack edge
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 1. Undo Button
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.undo, size: 16),
              label: const Text('Desfazer', style: TextStyle(fontSize: 12)),
              onPressed: () {
                setState(() {
                  _controller.undoChanges();
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          
          // 2. Buy/Pass Button
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey.shade800,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.add_box, size: 16),
              label: const Text('Comprar Peça', style: TextStyle(fontSize: 12)),
              onPressed: () {
                setState(() {
                  _controller.drawTile();
                });
                if (_controller.isGameOver) {
                  _showGameOverDialog();
                } else {
                  _triggerBotTurnIfNeeded();
                }
              },
            ),
          ),
          const SizedBox(width: 8),

          // 3. Play Turn Button
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50), // Green
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.check_circle, size: 16),
              label: const Text('Enviar Jogada', style: TextStyle(fontSize: 12)),
              onPressed: _submitTurn,
            ),
          ),
        ],
      ),
    );
  }

  // --- Turn Submission ---

  void _submitTurn() {
    final error = _controller.validateTurn();
    if (error != null) {
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1B3B2B),
          title: const Text('Jogada Inválida', style: TextStyle(color: Colors.redAccent)),
          content: Text(error, style: const TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              child: const Text('OK', style: TextStyle(color: Color(0xFFFDD835))),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
      );
      return;
    }

    setState(() {
      _controller.commitTurn();
    });

    if (_controller.isGameOver) {
      _showGameOverDialog();
    } else {
      _triggerBotTurnIfNeeded();
    }
  }

  // --- Bot Turn Logic Execution ---

  Future<void> _triggerBotTurnIfNeeded() async {
    if (_controller.isGameOver) return;
    if (_controller.currentPlayer.isHuman) return;

    setState(() {
      _isBotThinking = true;
      _botThinkingName = _controller.currentPlayer.name;
    });

    // Simulated Thinking Delay (gives organic feeling)
    await Future.delayed(const Duration(milliseconds: 1800));

    if (!mounted) return;

    final bot = _controller.currentPlayer;
    AIBase ai;
    switch (bot.aiLevel!) {
      case AILevel.easy:
        ai = AIEasy();
        break;
      case AILevel.medium:
        ai = AIMedium();
        break;
      case AILevel.hard:
        ai = AIHard();
        break;
    }

    final playResult = ai.playTurn(
      _controller.board,
      bot.tiles,
      bot.hasMadeInitialMeld,
    );

    if (playResult != null) {
      final oldTilesCount = bot.tiles.length;
      final newTilesCount = playResult.value.length;
      final playedCount = oldTilesCount - newTilesCount;

      setState(() {
        _controller.board = playResult.key;
        _controller.players[_controller.currentPlayerIndex] = bot.copyWith(
          tiles: playResult.value,
          hasMadeInitialMeld: true,
        );

        _controller.gameLog.add(
          '[${DateTime.now().toLocal().toString().substring(11, 16)}] '
          '${bot.name} jogou $playedCount peça(s).'
        );

        if (playResult.value.isEmpty) {
          _controller.isGameOver = true;
          _controller.winner = bot;
          _controller.gameLog.add(
            '[${DateTime.now().toLocal().toString().substring(11, 16)}] '
            '${bot.name} esvaziou a mão e venceu o jogo!'
          );
          _isBotThinking = false;
          _showGameOverDialog();
        } else {
          _controller.nextTurn();
          _isBotThinking = false;
        }
      });
    } else {
      setState(() {
        _controller.drawTile(); // Reverts, draws tile, logs, and goes nextTurn()
        _isBotThinking = false;
      });
      if (_controller.isGameOver) {
        _showGameOverDialog();
        return;
      }
    }

    // Recurse if next player is also a bot
    if (!_controller.currentPlayer.isHuman && !_controller.isGameOver) {
      _triggerBotTurnIfNeeded();
    }
  }

  // --- Overlays and Dialogs ---

  void _showGameLogsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F261C),
        title: const Row(
          children: [
            Icon(Icons.history, color: Color(0xFFFDD835)),
            SizedBox(width: 8),
            Text('Histórico da Partida', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _controller.gameLog.isEmpty
              ? const Center(child: Text('Nenhuma jogada registrada.', style: TextStyle(color: Colors.white54)))
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _controller.gameLog.length,
                  itemBuilder: (context, index) {
                    final log = _controller.gameLog[_controller.gameLog.length - 1 - index]; // Reverse order
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        log,
                        style: const TextStyle(color: Colors.white70, fontSize: 13, fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            child: const Text('FECHAR', style: TextStyle(color: Color(0xFFFDD835))),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _showRulesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F261C),
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Color(0xFFFDD835)),
            SizedBox(width: 8),
            Text('Regras Rápidas', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Objetivo:',
                style: TextStyle(color: Color(0xFFFDD835), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'Esvaziar o seu suporte baixando peças na mesa em grupos ou sequências.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 12),
              Text(
                'Abertura Inicial:',
                style: TextStyle(color: Color(0xFFFDD835), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'Sua primeira jogada deve consistir em novos grupos/sequências de seu suporte que somem no mínimo 30 pontos. Não é permitido mexer na mesa antes de abrir.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 12),
              Text(
                'Combinações Válidas (mínimo 3 peças):',
                style: TextStyle(color: Color(0xFFFDD835), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                '• Sequência: Peças de mesma cor consecutivas (ex: 4-5-6 Azul).\n'
                '• Grupo: Peças do mesmo número com cores diferentes (ex: 8 Vermelho, 8 Preto, 8 Amarelo).',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              SizedBox(height: 12),
              Text(
                'Regra do Coringa:',
                style: TextStyle(color: Color(0xFFFDD835), fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                'Para retirar ou mexer em um Coringa que está na mesa, você deve substituí-lo pela peça exata que ele representa de sua própria mão. O Coringa retirado deve ser jogado imediatamente em uma nova combinação junto com pelo menos 2 peças de sua mão.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('ENTENDI', style: TextStyle(color: Color(0xFFFDD835))),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    final winnerName = _controller.winner?.name ?? 'Empate';
    final isHumanWinner = _controller.winner?.isHuman == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F261C),
        title: Center(
          child: Text(
            isHumanWinner ? '🏆 PARABÉNS!' : 'FIM DE JOGO',
            style: TextStyle(
              color: isHumanWinner ? const Color(0xFFFDD835) : Colors.redAccent,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHumanWinner ? 'Você venceu a partida!' : '$winnerName venceu o jogo.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Pontos restantes nos suportes:',
              style: TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ..._controller.players.map((p) {
              final pts = p.tiles.fold(0, (sum, tile) => sum + (tile.isJoker ? 30 : tile.number!));
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(p.name, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    Text('$pts pts (${p.tiles.length} peças)', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              );
            }),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFDD835),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('VOLTAR AO MENU', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _isPlaying = false;
                });
              },
            ),
          )
        ],
      ),
    );
  }
}
