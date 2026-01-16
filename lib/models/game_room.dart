import 'playing_card.dart';

class GameRoom {
  final String roomId;
  final String hostPlayerId;
  String? guestPlayerId;
  final DateTime createdAt;
  GameRoomState state;
  List<CardData> deckCards;
  List<CardData> discardPile;
  List<PlayerData> players;
  int currentPlayerIndex;
  String currentPhase;
  String? message;

  GameRoom({
    required this.roomId,
    required this.hostPlayerId,
    this.guestPlayerId,
    required this.createdAt,
    required this.state,
    required this.deckCards,
    required this.discardPile,
    required this.players,
    this.currentPlayerIndex = 0,
    this.currentPhase = 'draw',
    this.message,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'hostPlayerId': hostPlayerId,
      'guestPlayerId': guestPlayerId,
      'createdAt': createdAt.toIso8601String(),
      'state': state.toString().split('.').last,
      'deckCards': deckCards.map((c) => c.toJson()).toList(),
      'discardPile': discardPile.map((c) => c.toJson()).toList(),
      'players': players.map((p) => p.toJson()).toList(),
      'currentPlayerIndex': currentPlayerIndex,
      'currentPhase': currentPhase,
      'message': message,
    };
  }

  factory GameRoom.fromJson(Map<dynamic, dynamic> json) {
    return GameRoom(
      roomId: json['roomId'] as String,
      hostPlayerId: json['hostPlayerId'] as String,
      guestPlayerId: json['guestPlayerId'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      state: GameRoomState.values.firstWhere(
        (e) => e.toString().split('.').last == json['state'],
      ),
      deckCards: (json['deckCards'] as List)
          .map((c) => CardData.fromJson(c))
          .toList(),
      discardPile: (json['discardPile'] as List)
          .map((c) => CardData.fromJson(c))
          .toList(),
      players: (json['players'] as List)
          .map((p) => PlayerData.fromJson(p))
          .toList(),
      currentPlayerIndex: json['currentPlayerIndex'] as int,
      currentPhase: json['currentPhase'] as String,
      message: json['message'] as String?,
    );
  }
}

enum GameRoomState {
  waiting,
  playing,
  finished,
}

class CardData {
  final String suit;
  final String rank;
  final bool isJoker;

  CardData({
    required this.suit,
    required this.rank,
    this.isJoker = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'suit': suit,
      'rank': rank,
      'isJoker': isJoker,
    };
  }

  factory CardData.fromJson(Map<dynamic, dynamic> json) {
    return CardData(
      suit: json['suit'] as String,
      rank: json['rank'] as String,
      isJoker: json['isJoker'] as bool? ?? false,
    );
  }

  PlayingCard toPlayingCard() {
    if (isJoker) {
      return PlayingCard(
        suit: Suit.values.firstWhere((s) => s.toString().split('.').last == suit),
        rank: Rank.values.firstWhere((r) => r.toString().split('.').last == rank),
        isJoker: true,
      );
    }
    return PlayingCard(
      suit: Suit.values.firstWhere((s) => s.toString().split('.').last == suit),
      rank: Rank.values.firstWhere((r) => r.toString().split('.').last == rank),
    );
  }

  static CardData fromPlayingCard(PlayingCard card) {
    return CardData(
      suit: card.suit.toString().split('.').last,
      rank: card.rank.toString().split('.').last,
      isJoker: card.isJoker,
    );
  }
}

class PlayerData {
  final String playerId;
  final String name;
  List<CardData> hand;
  List<MeldData> melds;
  int score;

  PlayerData({
    required this.playerId,
    required this.name,
    required this.hand,
    required this.melds,
    this.score = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'name': name,
      'hand': hand.map((c) => c.toJson()).toList(),
      'melds': melds.map((m) => m.toJson()).toList(),
      'score': score,
    };
  }

  factory PlayerData.fromJson(Map<dynamic, dynamic> json) {
    return PlayerData(
      playerId: json['playerId'] as String,
      name: json['name'] as String,
      hand: (json['hand'] as List).map((c) => CardData.fromJson(c)).toList(),
      melds: (json['melds'] as List).map((m) => MeldData.fromJson(m)).toList(),
      score: json['score'] as int? ?? 0,
    );
  }
}

class MeldData {
  final List<CardData> cards;
  final String type;

  MeldData({
    required this.cards,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'cards': cards.map((c) => c.toJson()).toList(),
      'type': type,
    };
  }

  factory MeldData.fromJson(Map<dynamic, dynamic> json) {
    return MeldData(
      cards: (json['cards'] as List).map((c) => CardData.fromJson(c)).toList(),
      type: json['type'] as String,
    );
  }
}
