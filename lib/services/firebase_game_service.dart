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

    for (var i = 0; i < 13; i++) {
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

  Future<void> drawFromDiscard(String roomId, String playerId) async {
    final roomRef = _database.child('rooms').child(roomId);
    final snapshot = await roomRef.get();

    if (!snapshot.exists) return;

    final room = GameRoom.fromJson(snapshot.value as Map);
    final playerIndex = room.players.indexWhere((p) => p.playerId == playerId);

    if (playerIndex != room.currentPlayerIndex) return;
    if (room.currentPhase != 'draw') return;
    if (room.discardPile.isEmpty) return;

    final card = room.discardPile.removeLast();
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
      'discardPile': room.discardPile.map((c) => c.toJson()).toList(),
      'players': room.players.map((p) => p.toJson()).toList(),
      'currentPhase': room.currentPhase,
      'message': room.message,
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

    cardIndices.sort((a, b) => b.compareTo(a));
    for (final index in cardIndices) {
      room.players[playerIndex].hand.removeAt(index);
    }

    room.players[playerIndex].melds.add(MeldData(cards: cards, type: meldType));

    room.message = '${room.players[playerIndex].name} played a $meldType';

    await roomRef.update({
      'players': room.players.map((p) => p.toJson()).toList(),
      'message': room.message,
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

    final card = room.players[playerIndex].hand.removeAt(handIndex);
    room.discardPile.add(card);

    if (room.players[playerIndex].hand.isEmpty) {
      await _endRound(roomRef, room);
    } else {
      room.currentPlayerIndex =
          (room.currentPlayerIndex + 1) % room.players.length;
      room.currentPhase = 'draw';
      room.message =
          '${room.players[room.currentPlayerIndex].name}\'s turn - Draw a card';

      await roomRef.update({
        'players': room.players.map((p) => p.toJson()).toList(),
        'discardPile': room.discardPile.map((c) => c.toJson()).toList(),
        'currentPlayerIndex': room.currentPlayerIndex,
        'currentPhase': room.currentPhase,
        'message': room.message,
      });
    }
  }

  Future<void> _endRound(DatabaseReference roomRef, GameRoom room) async {
    for (final player in room.players) {
      int meldPoints = 0;
      for (final meld in player.melds) {
        for (final card in meld.cards) {
          meldPoints += card.toPlayingCard().points;
        }
      }

      int handPoints = 0;
      for (final card in player.hand) {
        handPoints += card.toPlayingCard().points;
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

  Future<void> deleteGameRoom(String roomId) async {
    await _database.child('rooms').child(roomId).remove();
  }

  String getGameUrl(String roomId) {
    return 'https://cardly.kita.llc/join/$roomId';
  }
}
