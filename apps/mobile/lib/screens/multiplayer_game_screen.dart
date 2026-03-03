import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/game_room.dart';
import '../services/game_service.dart';
import '../widgets/card_widget.dart';
import '../widgets/discard_pile_widget.dart';
import '../widgets/player_hand.dart';

class MultiplayerGameScreen extends StatefulWidget {
  const MultiplayerGameScreen({
    required this.roomId,
    required this.playerId,
    required this.isHost,
    super.key,
  });
  final String roomId;
  final String playerId;
  final bool isHost;

  @override
  State<MultiplayerGameScreen> createState() => _MultiplayerGameScreenState();
}

class _MultiplayerGameScreenState extends State<MultiplayerGameScreen> {
  late final GameService _gameService;
  GameRoom? _gameRoom;
  final List<int> _selectedHandIndices = [];
  bool _showShareDialog = false;

  @override
  void initState() {
    super.initState();
    _gameService = context.read<GameService>();
    if (widget.isHost) {
      _showShareDialog = true;
    }
  }

  PlayerData? get _currentPlayer {
    if (_gameRoom == null) return null;
    return _gameRoom!.players.firstWhere(
      (p) => p.playerId == widget.playerId,
      orElse: () => _gameRoom!.players.first,
    );
  }

  PlayerData? get _opponentPlayer {
    if (_gameRoom == null) return null;
    return _gameRoom!.players.firstWhere(
      (p) => p.playerId != widget.playerId,
      orElse: () => _gameRoom!.players.last,
    );
  }

  bool get _isMyTurn {
    if (_gameRoom == null) return false;
    final currentIndex = _gameRoom!.currentPlayerIndex;
    if (currentIndex >= _gameRoom!.players.length) return false;
    return _gameRoom!.players[currentIndex].playerId == widget.playerId;
  }

  void _shareRoomCode() {
    final url = _gameService.getGameUrl(widget.roomId);
    Share.share(
      'Join my Rummy 500 game!\nRoom Code: ${widget.roomId}\nOr use this link: $url',
      subject: 'Join my Rummy 500 game',
    );
  }

  void _copyRoomCode() {
    Clipboard.setData(ClipboardData(text: widget.roomId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Room code copied to clipboard!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleCardTap(int index) {
    if (!_isMyTurn) return;

    setState(() {
      if (_selectedHandIndices.contains(index)) {
        _selectedHandIndices.remove(index);
      } else {
        _selectedHandIndices.add(index);
      }
    });
  }

  Future<void> _handleDrawFromDeck() async {
    if (!_isMyTurn) return;
    await _gameService.drawFromDeck(widget.roomId, widget.playerId);
    setState(_selectedHandIndices.clear);
  }

  Future<void> _handleDrawFromDiscard(int discardIndex) async {
    if (!_isMyTurn) return;
    await _gameService.drawFromDiscard(
      widget.roomId,
      widget.playerId,
      discardIndex,
    );
    setState(_selectedHandIndices.clear);
  }

  Future<void> _handlePlaySet() async {
    if (!_isMyTurn) return;
    final success = await _gameService.playMeld(
      widget.roomId,
      widget.playerId,
      _selectedHandIndices,
      'set',
    );
    if (success) {
      setState(_selectedHandIndices.clear);
    }
  }

  Future<void> _handlePlayRun() async {
    if (!_isMyTurn) return;
    final success = await _gameService.playMeld(
      widget.roomId,
      widget.playerId,
      _selectedHandIndices,
      'run',
    );
    if (success) {
      setState(_selectedHandIndices.clear);
    }
  }

  Future<void> _handleDiscard() async {
    if (!_isMyTurn) return;
    if (_selectedHandIndices.length != 1) return;

    await _gameService.discard(
      widget.roomId,
      widget.playerId,
      _selectedHandIndices.first,
    );
    setState(_selectedHandIndices.clear);
  }

  void _handleClearSelection() {
    setState(_selectedHandIndices.clear);
  }

  Future<void> _handleUndoDiscardDraw() async {
    if (!_isMyTurn) return;
    await _gameService.undoDiscardDraw(widget.roomId, widget.playerId);
    setState(_selectedHandIndices.clear);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<GameRoom?>(
      stream: _gameService.watchGameRoom(widget.roomId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        _gameRoom = snapshot.data;

        if (_gameRoom == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Game Not Found')),
            body: const Center(child: Text('This game room no longer exists')),
          );
        }

        if (_gameRoom!.state == GameRoomState.waiting) {
          return _buildWaitingScreen();
        }

        if (_gameRoom!.state == GameRoomState.finished) {
          return _buildFinishedScreen();
        }

        return _buildGameScreen();
      },
    );
  }

  Widget _buildWaitingScreen() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_showShareDialog) {
        _showShareDialog = false;
        _showShareRoomDialog();
      }
    });

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Room: ${widget.roomId}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Waiting for another player...',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('Room Code:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Text(
                    widget.roomId,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _copyRoomCode,
                        icon: const Icon(Icons.copy),
                        label: const Text('Copy Code'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: _shareRoomCode,
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinishedScreen() {
    final winner = _gameRoom!.players.reduce(
      (a, b) => a.score > b.score ? a : b,
    );
    final isWinner = winner.playerId == widget.playerId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Game Over'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isWinner ? Icons.emoji_events : Icons.sentiment_neutral,
              size: 100,
              color: isWinner ? Colors.amber : Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              isWinner ? 'You Win!' : 'You Lost',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isWinner ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _gameRoom!.message ?? '${winner.name} wins with ${winner.score} points!',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back to Lobby'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameScreen() {
    final currentPlayer = _currentPlayer;
    final opponent = _opponentPlayer;

    if (currentPlayer == null || opponent == null) {
      return const Scaffold(body: Center(child: Text('Loading players...')));
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Room: ${widget.roomId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareRoomCode,
            tooltip: 'Share Room Code',
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
                  _buildScoreDisplay(currentPlayer, isCurrentPlayer: true),
                  _buildScoreDisplay(opponent, isCurrentPlayer: false),
                ],
              ),
            ),
            if (_gameRoom!.message != null)
              Container(
                padding: const EdgeInsets.all(8),
                color: _isMyTurn ? Colors.green.shade100 : Colors.blue.shade100,
                width: double.infinity,
                child: Text(
                  _gameRoom!.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          CardStackWidget(
                            cards: _gameRoom!.deckCards
                                .map((c) => c.toPlayingCard())
                                .toList(),
                            onTap:
                                _isMyTurn && _gameRoom!.currentPhase == 'draw'
                                ? _handleDrawFromDeck
                                : null,
                            label: 'Draw Pile',
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: DiscardPileWidget(
                              discardPile: _gameRoom!.discardPile
                                  .map((c) => c.toPlayingCard())
                                  .toList(),
                              onDiscardTap:
                                  _isMyTurn && _gameRoom!.currentPhase == 'draw'
                                  ? _handleDrawFromDiscard
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (opponent.melds.isNotEmpty)
                        _buildMeldsDisplay(opponent, isOpponent: true),
                      const SizedBox(height: 16),
                      if (currentPlayer.melds.isNotEmpty)
                        _buildMeldsDisplay(currentPlayer, isOpponent: false),
                      const SizedBox(height: 16),
                      if (_isMyTurn) _buildGameControls(),
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
                        hand: currentPlayer.hand
                            .map((c) => c.toPlayingCard())
                            .toList(),
                        selectedIndices: _selectedHandIndices,
                        onCardTap: _handleCardTap,
                        isCurrentPlayer: _isMyTurn,
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

  Widget _buildScoreDisplay(
    PlayerData player, {
    required bool isCurrentPlayer,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              isCurrentPlayer ? '${player.name} (You)' : player.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_gameRoom!.players[_gameRoom!.currentPlayerIndex].playerId ==
                player.playerId)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'TURN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        Text(
          '${player.score} pts',
          style: TextStyle(
            fontSize: 18,
            color: player.score >= 500 ? Colors.green : Colors.black,
            fontWeight: player.score >= 500
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildMeldsDisplay(PlayerData player, {required bool isOpponent}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isOpponent ? '${player.name}\'s Melds' : 'Your Melds',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...player.melds.map((meldData) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green),
              borderRadius: BorderRadius.circular(8),
              color: Colors.green.shade50,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meldData.type == 'set' ? 'Set' : 'Run',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: meldData.cards.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: CardWidget(
                          card: meldData.cards[index].toPlayingCard(),
                          width: 50,
                          height: 70,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildGameControls() {
    final isDrawPhase = _gameRoom!.currentPhase == 'draw';
    final hasSelection = _selectedHandIndices.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Your Turn - ${isDrawPhase ? "DRAW" : "PLAY/DISCARD"}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (isDrawPhase) ...[
            ElevatedButton.icon(
              onPressed: _handleDrawFromDeck,
              icon: const Icon(Icons.style),
              label: const Text('Draw from Deck'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _gameRoom!.discardPile.isNotEmpty
                  ? () => _handleDrawFromDiscard(_gameRoom!.discardPile.length - 1)
                  : null,
              icon: const Icon(Icons.layers),
              label: const Text('Draw Top Discard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Or tap a card in the discard pile to draw from there',
              style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic),
            ),
          ],
          if (!isDrawPhase) ...[
            // Show undo button if drew from discard but haven't used the card
            if (_gameRoom!.cardsDrawnFromDiscard.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'You must use the drawn card in a meld!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _handleUndoDiscardDraw,
                icon: const Icon(Icons.undo),
                label: const Text('Undo & Restart Turn'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (hasSelection) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedHandIndices.length >= 3
                          ? _handlePlaySet
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Play Set'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedHandIndices.length >= 3
                          ? _handlePlayRun
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Play Run'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedHandIndices.length == 1 &&
                              _gameRoom!.cardsDrawnFromDiscard.isEmpty
                          ? _handleDiscard
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Discard'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _handleClearSelection,
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedHandIndices.length} card(s) selected',
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              const Text(
                'Select cards from your hand to:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                '• 3+ cards to play a Set or Run',
                style: TextStyle(fontSize: 12),
              ),
              if (_gameRoom!.cardsDrawnFromDiscard.isEmpty)
                const Text(
                  '• 1 card to discard and end turn',
                  style: TextStyle(fontSize: 12),
                ),
            ],
          ],
        ],
      ),
    );
  }

  void _showShareRoomDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Share this room code with your friend:'),
            const SizedBox(height: 15),
            Text(
              widget.roomId,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    _copyRoomCode();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {
                    _shareRoomCode();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
