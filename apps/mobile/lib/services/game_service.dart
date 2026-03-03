import '../models/game_room.dart';

abstract class GameService {
  Future<GameRoom> createGameRoom(String hostPlayerId, String hostName);
  Future<GameRoom?> joinGameRoom(
    String roomId,
    String guestPlayerId,
    String guestName,
  );
  Stream<GameRoom?> watchGameRoom(String roomId);
  Future<void> drawFromDeck(String roomId, String playerId);
  Future<void> drawFromDiscard(
    String roomId,
    String playerId,
    int discardIndex,
  );
  Future<bool> playMeld(
    String roomId,
    String playerId,
    List<int> cardIndices,
    String meldType,
  );
  Future<void> discard(String roomId, String playerId, int handIndex);
  Future<bool> undoDiscardDraw(String roomId, String playerId);
  Future<void> deleteGameRoom(String roomId);
  String getGameUrl(String roomId);
}
