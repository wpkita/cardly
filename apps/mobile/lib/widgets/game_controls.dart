import 'package:flutter/material.dart';

import '../models/rummy_game_state.dart';

class GameControls extends StatelessWidget {
  const GameControls({
    required this.gameState,
    required this.onDrawFromDeck,
    super.key,
    this.onDrawFromDiscard,
    this.onPlaySet,
    this.onPlayRun,
    this.onDiscard,
    this.onClearSelection,
    this.onUndoDiscardDraw,
  });
  final RummyGameState gameState;
  final VoidCallback onDrawFromDeck;
  final VoidCallback? onDrawFromDiscard;
  final VoidCallback? onPlaySet;
  final VoidCallback? onPlayRun;
  final VoidCallback? onDiscard;
  final VoidCallback? onClearSelection;
  final VoidCallback? onUndoDiscardDraw;

  @override
  Widget build(BuildContext context) {
    final isDrawPhase = gameState.currentPhase == GamePhase.draw;
    final isPlayPhase = gameState.currentPhase == GamePhase.play;
    final hasSelection = gameState.selectedHandIndices.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border.all(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Phase: ${_getPhaseText()}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (isDrawPhase) ...[
            ElevatedButton.icon(
              onPressed: onDrawFromDeck,
              icon: const Icon(Icons.style),
              label: const Text('Draw from Deck'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: gameState.discardPile.isNotEmpty
                  ? onDrawFromDiscard
                  : null,
              icon: const Icon(Icons.layers),
              label: const Text('Draw from Discard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
          if (isPlayPhase) ...[
            // Show undo button if drew from discard but haven't used the card
            if (gameState.mustUseCard != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'You must use ${gameState.mustUseCard!.rankSymbol}${gameState.mustUseCard!.suitSymbol} in a meld!',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onUndoDiscardDraw,
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
                      onPressed: gameState.selectedHandIndices.length >= 3
                          ? onPlaySet
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
                      onPressed: gameState.selectedHandIndices.length >= 3
                          ? onPlayRun
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
                      onPressed: gameState.selectedHandIndices.length == 1 &&
                              gameState.mustUseCard == null
                          ? onDiscard
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
                      onPressed: onClearSelection,
                      child: const Text('Clear'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${gameState.selectedHandIndices.length} card(s) selected',
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
              if (gameState.mustUseCard == null)
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

  String _getPhaseText() {
    switch (gameState.currentPhase) {
      case GamePhase.draw:
        return 'DRAW';
      case GamePhase.play:
        return 'PLAY/DISCARD';
      case GamePhase.discard:
        return 'DISCARD';
    }
  }
}
