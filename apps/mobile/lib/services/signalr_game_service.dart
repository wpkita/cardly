import 'dart:async';
import 'dart:convert';

import 'package:signalr_netcore/signalr_client.dart';

import '../models/game_room.dart';
import 'game_service.dart';

class SignalRGameService implements GameService {
  SignalRGameService({required this.baseUrl});

  final String baseUrl;

  HubConnection? _connection;
  final StreamController<GameRoom?> _gameStateController =
      StreamController<GameRoom?>.broadcast();

  Future<void> _ensureConnected() async {
    if (_connection != null &&
        _connection!.state == HubConnectionState.Connected) {
      return;
    }

    _connection = HubConnectionBuilder()
        .withUrl('$baseUrl/gameHub')
        .withAutomaticReconnect()
        .build();

    _connection!.on('ReceiveGameState', (arguments) {
      if (arguments == null || arguments.isEmpty) {
        _gameStateController.add(null);
        return;
      }
      final raw = arguments[0];
      Map<dynamic, dynamic> json;
      if (raw is String) {
        json = jsonDecode(raw) as Map<dynamic, dynamic>;
      } else if (raw is Map) {
        json = raw;
      } else {
        return;
      }
      _gameStateController.add(GameRoom.fromJson(json));
    });

    await _connection!.start();
  }

  @override
  Future<GameRoom> createGameRoom(
    String hostPlayerId,
    String hostName,
  ) async {
    await _ensureConnected();
    final result = await _connection!.invoke(
      'CreateRoom',
      args: [hostPlayerId, hostName],
    );
    final Map<dynamic, dynamic> json;
    if (result is String) {
      json = jsonDecode(result) as Map<dynamic, dynamic>;
    } else {
      json = result as Map<dynamic, dynamic>;
    }
    return GameRoom.fromJson(json);
  }

  @override
  Future<GameRoom?> joinGameRoom(
    String roomId,
    String guestPlayerId,
    String guestName,
  ) async {
    await _ensureConnected();
    final result = await _connection!.invoke(
      'JoinRoom',
      args: [roomId, guestPlayerId, guestName],
    );
    if (result == null) {
      return null;
    }
    final Map<dynamic, dynamic> json;
    if (result is String) {
      json = jsonDecode(result) as Map<dynamic, dynamic>;
    } else {
      json = result as Map<dynamic, dynamic>;
    }
    return GameRoom.fromJson(json);
  }

  @override
  Stream<GameRoom?> watchGameRoom(String roomId) {
    return _gameStateController.stream;
  }

  @override
  Future<void> drawFromDeck(String roomId, String playerId) async {
    await _ensureConnected();
    await _connection!.invoke('DrawFromDeck', args: [roomId, playerId]);
  }

  @override
  Future<void> drawFromDiscard(
    String roomId,
    String playerId,
    int discardIndex,
  ) async {
    await _ensureConnected();
    await _connection!.invoke(
      'DrawFromDiscard',
      args: [roomId, playerId, discardIndex],
    );
  }

  @override
  Future<bool> playMeld(
    String roomId,
    String playerId,
    List<int> cardIndices,
    String meldType,
  ) async {
    await _ensureConnected();
    final result = await _connection!.invoke(
      'PlayMeld',
      args: [roomId, playerId, cardIndices, meldType],
    );
    return result as bool? ?? false;
  }

  @override
  Future<void> discard(String roomId, String playerId, int handIndex) async {
    await _ensureConnected();
    await _connection!.invoke('Discard', args: [roomId, playerId, handIndex]);
  }

  @override
  Future<bool> undoDiscardDraw(String roomId, String playerId) async {
    await _ensureConnected();
    final result = await _connection!.invoke(
      'UndoDiscardDraw',
      args: [roomId, playerId],
    );
    return result as bool? ?? false;
  }

  @override
  Future<void> deleteGameRoom(String roomId) async {
    await _ensureConnected();
    await _connection!.invoke('DeleteRoom', args: [roomId]);
  }

  @override
  String getGameUrl(String roomId) {
    return 'https://cardly.kita.llc/join/$roomId';
  }
}
