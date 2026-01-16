import 'package:flutter/material.dart';
import '../screens/game_lobby_screen.dart';

class UrlHandler {
  static String? extractRoomIdFromUrl(String url) {
    final uri = Uri.parse(url);
    final path = uri.path;

    // Check for /join/ROOMCODE pattern
    if (path.contains('/join/')) {
      final parts = path.split('/');
      final joinIndex = parts.indexOf('join');
      if (joinIndex != -1 && joinIndex + 1 < parts.length) {
        return parts[joinIndex + 1].toUpperCase();
      }
    }

    return null;
  }

  static Widget? handleInitialRoute(String? initialRoute) {
    if (initialRoute == null || initialRoute == '/') {
      return null;
    }

    final roomId = extractRoomIdFromUrl(initialRoute);
    if (roomId != null) {
      return GameLobbyScreen(joinRoomId: roomId);
    }

    return null;
  }
}
