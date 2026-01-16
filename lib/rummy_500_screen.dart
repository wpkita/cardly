import 'package:flutter/material.dart';
import 'models/playing_card.dart';
import 'models/rummy_game_state.dart';
import 'widgets/card_widget.dart';
import 'widgets/player_hand.dart';
import 'widgets/discard_pile_widget.dart';
import 'widgets/meld_widget.dart';
import 'widgets/game_controls.dart';
import 'screens/game_lobby_screen.dart';

class Rummy500Screen extends StatefulWidget {
  const Rummy500Screen({super.key});

  @override
  State<Rummy500Screen> createState() => _Rummy500ScreenState();
}

class _Rummy500ScreenState extends State<Rummy500Screen> {
  late RummyGameState gameState;
  bool gameStarted = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  void _initializeGame() {
    final deck = Deck();
    deck.shuffle();

    gameState = RummyGameState(
      deck: deck,
      discardPile: [],
      players: [
        Player(name: 'You'),
        Player(name: 'Computer'),
      ],
      message: 'Tap "Start Game" to begin',
    );
  }

  void _startGame() {
    setState(() {
      _initializeGame();
      gameState.dealCards();
      gameState.message = 'Your turn - Draw a card';
      gameStarted = true;
    });
  }

  void _handleCardTap(int index) {
    setState(() {
      if (gameState.selectedHandIndices.contains(index)) {
        gameState.selectedHandIndices.remove(index);
      } else {
        gameState.selectedHandIndices.add(index);
      }
    });
  }

  void _handleDrawFromDeck() {
    setState(() {
      gameState.drawFromDeck();
      _checkComputerTurn();
    });
  }

  void _handleDrawFromDiscard() {
    if (gameState.discardPile.isEmpty) return;

    setState(() {
      gameState.drawFromDiscard(gameState.discardPile.length - 1);
      _checkComputerTurn();
    });
  }

  void _handlePlaySet() {
    setState(() {
      gameState.playMeld(gameState.selectedHandIndices, MeldType.set);
      _checkComputerTurn();
    });
  }

  void _handlePlayRun() {
    setState(() {
      gameState.playMeld(gameState.selectedHandIndices, MeldType.run);
      _checkComputerTurn();
    });
  }

  void _handleDiscard() {
    if (gameState.selectedHandIndices.length != 1) return;

    setState(() {
      gameState.discard(gameState.selectedHandIndices.first);
      _checkComputerTurn();
    });
  }

  void _handleClearSelection() {
    setState(() {
      gameState.selectedHandIndices.clear();
    });
  }

  void _checkComputerTurn() {
    if (gameState.currentPlayerIndex == 1 && !gameState.isGameOver) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _playComputerTurn();
      });
    }
  }

  void _playComputerTurn() {
    if (gameState.currentPlayerIndex != 1) return;

    setState(() {
      if (gameState.currentPhase == GamePhase.draw) {
        gameState.drawFromDeck();
      }

      _tryComputerMelds();

      if (gameState.currentPlayer.hand.isNotEmpty) {
        gameState.discard(0);
      }

      _checkComputerTurn();
    });
  }

  void _tryComputerMelds() {
    final hand = gameState.currentPlayer.hand;

    for (var i = 0; i < hand.length - 2; i++) {
      for (var j = i + 1; j < hand.length - 1; j++) {
        for (var k = j + 1; k < hand.length; k++) {
          final indices = [i, j, k];

          if (gameState.playMeld(indices, MeldType.set)) {
            _tryComputerMelds();
            return;
          }

          if (gameState.playMeld(indices, MeldType.run)) {
            _tryComputerMelds();
            return;
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!gameStarted) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Rummy 500'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.style,
                size: 100,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              const Text(
                'Rummy 500',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  'A classic card game where you try to reach 500 points by forming melds (sets and runs) of cards.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 30.0),
                child: Text(
                  'How to Play:\n'
                  '• Draw from deck or discard pile\n'
                  '• Form sets (3+ same rank) or runs (3+ consecutive cards)\n'
                  '• Discard to end your turn\n'
                  '• First to 500 points wins!',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameLobbyScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.people),
                label: const Text('Play Online (Multiplayer)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _startGame,
                icon: const Icon(Icons.computer),
                label: const Text('Play vs Computer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Rummy 500'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                gameStarted = false;
              });
            },
            tooltip: 'New Game',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.amber.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildScoreDisplay(gameState.players[0]),
                  _buildScoreDisplay(gameState.players[1]),
                ],
              ),
            ),
            if (gameState.message != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.blue.shade100,
                width: double.infinity,
                child: Text(
                  gameState.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CardStackWidget(
                            cards: gameState.deck.cards,
                            onTap: gameState.currentPhase == GamePhase.draw &&
                                    gameState.currentPlayerIndex == 0
                                ? _handleDrawFromDeck
                                : null,
                            label: 'Draw Pile',
                            faceDown: true,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: DiscardPileWidget(
                              discardPile: gameState.discardPile,
                              onDiscardTap:
                                  gameState.currentPhase == GamePhase.draw &&
                                          gameState.currentPlayerIndex == 0
                                      ? (index) => _handleDrawFromDiscard()
                                      : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (gameState.players[1].melds.isNotEmpty)
                        MeldsDisplay(
                          melds: gameState.players[1].melds,
                          playerName: gameState.players[1].name,
                          playerIndex: 1,
                        ),
                      const SizedBox(height: 16),
                      if (gameState.players[0].melds.isNotEmpty)
                        MeldsDisplay(
                          melds: gameState.players[0].melds,
                          playerName: gameState.players[0].name,
                          playerIndex: 0,
                        ),
                      const SizedBox(height: 16),
                      if (gameState.currentPlayerIndex == 0)
                        GameControls(
                          gameState: gameState,
                          onDrawFromDeck: _handleDrawFromDeck,
                          onDrawFromDiscard: _handleDrawFromDiscard,
                          onPlaySet: _handlePlaySet,
                          onPlayRun: _handlePlayRun,
                          onDiscard: _handleDiscard,
                          onClearSelection: _handleClearSelection,
                        ),
                      const SizedBox(height: 16),
                      const Text(
                        'Your Hand',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PlayerHand(
                        hand: gameState.players[0].hand,
                        selectedIndices: gameState.selectedHandIndices,
                        onCardTap: _handleCardTap,
                        isCurrentPlayer: gameState.currentPlayerIndex == 0,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreDisplay(Player player) {
    return Column(
      children: [
        Text(
          player.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          '${player.score} pts',
          style: TextStyle(
            fontSize: 18,
            color: player.score >= 500 ? Colors.green : Colors.black,
            fontWeight:
                player.score >= 500 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
