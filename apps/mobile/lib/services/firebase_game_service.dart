import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:uuid/uuid.dart';

import '../models/game_room.dart';
import '../models/playing_card.dart';
import '../models/rummy_game_state.dart';

class FirebaseGameService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final Uuid _uuid = const Uuid();

  Future<GameRoom> createGameRoom(String hostPlayerId, String hostName) async {
    final roomId = _uuid.v4().substring(0, 6).toUpperCase();

    final deck = Deck();
    deck.shuffle();

    final gameRoom = GameRoom(
      roomId: roomId,
      hostPlayerId: hostPlayerId,
      createdAt: DateTime.now(),
      state: GameRoomState.waiting,
      deckCards: deck.cards.map(CardData.fromPlayingCard).toList(),
      discardPile: [],
      players: [
        PlayerData(playerId: hostPlayerId, name: hostName, hand: [], melds: []),
      ],
      message: 'Waiting for another player to join...',
    );

    await _database.child('rooms').child(roomId).set(gameRoom.toJson());
    return gameRoom;
  }

  Future<GameRoom?> joinGameRoom(
    String roomId,
    String guestPlayerId,
    String guestName,
  ) async {
    final roomRef = _database.child('rooms').child(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) {
      return null;
    }

    final room = GameRoom.fromJson(snapshot.value as Map);

    if (room.state != GameRoomState.waiting) {
      return null;
    }

    room.guestPlayerId = guestPlayerId;
    room.players.add(
      PlayerData(playerId: guestPlayerId, name: guestName, hand: [], melds: []),
    );

    await roomRef.update({
      'guestPlayerId': guestPlayerId,
      'players': room.players.map((p) => p.toJson()).toList(),
    });

    await _dealCards(roomId, room);

    return room;
  }

  Future<void> _dealCards(String roomId, GameRoom room) async {
    final roomRef = _database.child('rooms').child(roomId);

    // Deal 7 cards per player normally, 13 cards in 2-player game
    final cardsPerPlayer = room.players.length == 2 ? 13 : 7;

    for (var i = 0; i < cardsPerPlayer; i++) {
      for (final player in room.players) {
        if (room.deckCards.isNotEmpty) {
          final card = room.deckCards.removeLast();
          player.hand.add(card);
        }
      }
    }

    if (room.deckCards.isNotEmpty) {
      room.discardPile.add(room.deckCards.removeLast());
    }

    for (final player in room.players) {
      player.hand.sort((a, b) {
        if (a.suit != b.suit) {
          return a.suit.compareTo(b.suit);
        }
        return a.rank.compareTo(b.rank);
      });
    }

    room.state = GameRoomState.playing;
    room.message = '${room.players[0].name}\'s turn - Draw a card';

    await roomRef.update({
      'state': room.state.toString().split('.').last,
      'deckCards': room.deckCards.map((c) => c.toJson()).toList(),
      'discardPile': room.discardPile.map((c) => c.toJson()).toList(),
      'players': room.players.map((p) => p.toJson()).toList(),
      'message': room.message,
    });
  }

  Stream<GameRoom?> watchGameRoom(String roomId) {
    return _database.child('rooms').child(roomId).onValue.map((event) {
      if (!event.snapshot.exists) {
        return null;
      }
      return GameRoom.fromJson(event.snapshot.value as Map);
    });
  }

  Future<void> drawFromDeck(String roomId, String playerId) async {
    final roomRef = _database.child('rooms').child(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) return;

    final room = GameRoom.fromJson(snapshot.value as Map);
    final playerIndex = room.players.indexWhere((p) => p.playerId == playerId);

    if (playerIndex != room.currentPlayerIndex) return;
    if (room.currentPhase != 'draw') return;
    if (room.deckCards.isEmpty) return;

    final card = room.deckCards.removeLast();
    room.players[playerIndex].hand.add(card);
    room.players[playerIndex].hand.sort((a, b) {
      if (a.suit != b.suit) {
        return a.suit.compareTo(b.suit);
      }
      return a.rank.compareTo(b.rank);
    });

    room.currentPhase = 'play';
    room.message = '${room.players[playerIndex].name} - Play melds or discard';

    await roomRef.update({
      'deckCards': room.deckCards.map((c) => c.toJson()).toList(),
      'players': room.players.map((p) => p.toJson()).toList(),
      'currentPhase': room.currentPhase,
      'message': room.message,
    });
  }

  Future<void> drawFromDiscard(
    String roomId,
    String playerId,
    int discardIndex,
  ) async {
    final roomRef = _database.child('rooms').child(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) return;

    final room = GameRoom.fromJson(snapshot.value as Map);
    final playerIndex = room.players.indexWhere((p) => p.playerId == playerId);

    if (playerIndex != room.currentPlayerIndex) return;
    if (room.currentPhase != 'draw') return;
    if (room.discardPile.isEmpty) return;
    if (discardIndex < 0 || discardIndex >= room.discardPile.length) return;

    // The selected card that must be immediately used
    final selectedCard = room.discardPile[discardIndex];
    room.mustUseCard = selectedCard;

    // Track all cards drawn for undo functionality
    room.cardsDrawnFromDiscard.clear();
    for (var i = discardIndex; i < room.discardPile.length; i++) {
      room.cardsDrawnFromDiscard.add(room.discardPile[i]);
    }

    // Take all cards from the selected one to the top
    for (var i = room.discardPile.length - 1; i >= discardIndex; i--) {
      room.players[playerIndex].hand.add(room.discardPile[i]);
    }
    room.discardPile.removeRange(discardIndex, room.discardPile.length);

    room.players[playerIndex].hand.sort((a, b) {
      if (a.suit != b.suit) {
        return a.suit.compareTo(b.suit);
      }
      return a.rank.compareTo(b.rank);
    });

    room.currentPhase = 'play';
    room.message =
        'Drew ${room.cardsDrawnFromDiscard.length} card(s) from discard. Must use the selected card in a meld!';

    await roomRef.update({
      'discardPile': room.discardPile.map((c) => c.toJson()).toList(),
      'players': room.players.map((p) => p.toJson()).toList(),
      'currentPhase': room.currentPhase,
      'message': room.message,
      'mustUseCard': room.mustUseCard?.toJson(),
      'cardsDrawnFromDiscard':
          room.cardsDrawnFromDiscard.map((c) => c.toJson()).toList(),
    });
  }

  Future<bool> playMeld(
    String roomId,
    String playerId,
    List<int> cardIndices,
    String meldType,
  ) async {
    final roomRef = _database.child('rooms').child(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) return false;

    final room = GameRoom.fromJson(snapshot.value as Map);
    final playerIndex = room.players.indexWhere((p) => p.playerId == playerId);

    if (playerIndex != room.currentPlayerIndex) return false;
    if (room.currentPhase != 'play') return false;
    if (cardIndices.length < 3) return false;

    final cards = cardIndices
        .map((i) => room.players[playerIndex].hand[i])
        .toList();
    final playingCards = cards.map((c) => c.toPlayingCard()).toList();
    final meld = Meld(
      cards: playingCards,
      type: meldType == 'set' ? MeldType.set : MeldType.run,
    );

    if (!meld.isValid()) {
      room.message = 'Invalid meld!';
      await roomRef.update({'message': room.message});
      return false;
    }

    // Check if this meld uses the required card from discard pile
    if (room.mustUseCard != null && cards.contains(room.mustUseCard)) {
      room.mustUseCard = null;
      room.cardsDrawnFromDiscard.clear();
    }

    cardIndices.sort((a, b) => b.compareTo(a));
    for (final index in cardIndices) {
      room.players[playerIndex].hand.removeAt(index);
    }

    room.players[playerIndex].melds.add(MeldData(cards: cards, type: meldType));

    room.message = '${room.players[playerIndex].name} played a $meldType';

    await roomRef.update({
      'players': room.players.map((p) => p.toJson()).toList(),
      'message': room.message,
      'mustUseCard': room.mustUseCard?.toJson(),
      'cardsDrawnFromDiscard':
          room.cardsDrawnFromDiscard.map((c) => c.toJson()).toList(),
    });

    return true;
  }

  Future<void> discard(String roomId, String playerId, int handIndex) async {
    final roomRef = _database.child('rooms').child(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) return;

    final room = GameRoom.fromJson(snapshot.value as Map);
    final playerIndex = room.players.indexWhere((p) => p.playerId == playerId);

    if (playerIndex != room.currentPlayerIndex) return;
    if (room.currentPhase != 'play') return;
    if (handIndex < 0 || handIndex >= room.players[playerIndex].hand.length) {
      return;
    }

    // Must use the drawn card from discard pile before discarding
    if (room.mustUseCard != null) {
      room.message =
          'You must use the drawn card in a meld or lay it off first!';
      await roomRef.update({'message': room.message});
      return;
    }

    final card = room.players[playerIndex].hand.removeAt(handIndex);
    room.discardPile.add(card);

    if (room.players[playerIndex].hand.isEmpty) {
      await _endRound(roomRef, room);
    } else {
      room.currentPlayerIndex =
          (room.currentPlayerIndex + 1) % room.players.length;
      room.currentPhase = 'draw';
      room.mustUseCard = null;
      room.cardsDrawnFromDiscard.clear();
      room.message =
          '${room.players[room.currentPlayerIndex].name}\'s turn - Draw a card';

      await roomRef.update({
        'players': room.players.map((p) => p.toJson()).toList(),
        'discardPile': room.discardPile.map((c) => c.toJson()).toList(),
        'currentPlayerIndex': room.currentPlayerIndex,
        'currentPhase': room.currentPhase,
        'message': room.message,
        'mustUseCard': null,
        'cardsDrawnFromDiscard': [],
      });
    }
  }

  Future<void> _endRound(DatabaseReference roomRef, GameRoom room) async {
    for (final player in room.players) {
      // Calculate meld points using the Meld class for proper ace handling
      int meldPoints = 0;
      for (final meldData in player.melds) {
        final playingCards =
            meldData.cards.map((c) => c.toPlayingCard()).toList();
        final meld = Meld(
          cards: playingCards,
          type: meldData.type == 'set' ? MeldType.set : MeldType.run,
        );
        meldPoints += meld.points;
      }

      int handPoints = 0;
      for (final card in player.hand) {
        handPoints += card.toPlayingCard().points();
      }

      player.score += meldPoints - handPoints;
    }

    final winner = room.players.reduce((a, b) => a.score > b.score ? a : b);

    if (winner.score >= 500) {
      room.state = GameRoomState.finished;
      room.message = '${winner.name} wins with ${winner.score} points!';

      await roomRef.update({
        'state': room.state.toString().split('.').last,
        'players': room.players.map((p) => p.toJson()).toList(),
        'message': room.message,
      });
    } else {
      await _startNewRound(roomRef, room);
    }
  }

  Future<void> _startNewRound(DatabaseReference roomRef, GameRoom room) async {
    final deck = Deck();
    deck.shuffle();

    room.deckCards = deck.cards.map(CardData.fromPlayingCard).toList();
    room.discardPile.clear();

    for (final player in room.players) {
      player.hand.clear();
      player.melds.clear();
    }

    room.currentPlayerIndex = 0;
    room.currentPhase = 'draw';
    room.message = 'New round starting...';

    await roomRef.update({
      'deckCards': room.deckCards.map((c) => c.toJson()).toList(),
      'discardPile': room.discardPile.map((c) => c.toJson()).toList(),
      'players': room.players.map((p) => p.toJson()).toList(),
      'currentPlayerIndex': room.currentPlayerIndex,
      'currentPhase': room.currentPhase,
      'message': room.message,
    });

    await _dealCards(room.roomId, room);
  }

  Future<bool> undoDiscardDraw(String roomId, String playerId) async {
    final roomRef = _database.child('rooms').child(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) return false;

    final room = GameRoom.fromJson(snapshot.value as Map);
    final playerIndex = room.players.indexWhere((p) => p.playerId == playerId);

    if (playerIndex != room.currentPlayerIndex) return false;
    if (room.cardsDrawnFromDiscard.isEmpty) return false;

    // Remove all the drawn cards from player's hand
    for (final card in room.cardsDrawnFromDiscard) {
      room.players[playerIndex].hand.removeWhere(
        (c) => c.suit == card.suit && c.rank == card.rank,
      );
    }

    // Put them back on the discard pile in original order
    room.discardPile.addAll(room.cardsDrawnFromDiscard);

    // Reset state to draw phase
    room.cardsDrawnFromDiscard.clear();
    room.mustUseCard = null;
    room.currentPhase = 'draw';
    room.message = 'Turn restarted. Draw a card.';

    await roomRef.update({
      'players': room.players.map((p) => p.toJson()).toList(),
      'discardPile': room.discardPile.map((c) => c.toJson()).toList(),
      'mustUseCard': null,
      'cardsDrawnFromDiscard': [],
      'currentPhase': room.currentPhase,
      'message': room.message,
    });

    return true;
  }

  Future<void> deleteGameRoom(String roomId) async {
    await _database.child('rooms').child(roomId).remove();
  }

  String getGameUrl(String roomId) {
    return 'https://cardly.kita.llc/join/$roomId';
  }
}
