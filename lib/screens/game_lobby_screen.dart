import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/game_room.dart';
import '../services/firebase_game_service.dart';
import 'multiplayer_game_screen.dart';

class GameLobbyScreen extends StatefulWidget {
  final String? joinRoomId;

  const GameLobbyScreen({super.key, this.joinRoomId});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  final FirebaseGameService _gameService = FirebaseGameService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  final String _playerId = const Uuid().v4();

  bool _isCreating = false;
  bool _isJoining = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.joinRoomId != null) {
      _roomCodeController.text = widget.joinRoomId!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createGame() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final room = await _gameService.createGameRoom(
        _playerId,
        _nameController.text.trim(),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerGameScreen(
            roomId: room.roomId,
            playerId: _playerId,
            isHost: true,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to create game: $e';
          _isCreating = false;
        });
      }
    }
  }

  Future<void> _joinGame() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your name';
      });
      return;
    }

    if (_roomCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter room code';
      });
      return;
    }

    setState(() {
      _isJoining = true;
      _errorMessage = null;
    });

    try {
      final room = await _gameService.joinGameRoom(
        _roomCodeController.text.trim().toUpperCase(),
        _playerId,
        _nameController.text.trim(),
      );

      if (!mounted) return;

      if (room == null) {
        setState(() {
          _errorMessage = 'Room not found or game already started';
          _isJoining = false;
        });
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MultiplayerGameScreen(
            roomId: room.roomId,
            playerId: _playerId,
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to join game: $e';
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // If joining via link, show simplified join screen
    if (widget.joinRoomId != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Join Game'),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.people,
                    size: 100,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    'Join Rummy 500 Game',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'You\'ve been invited to play!',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200, width: 2),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Room Code',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.joinRoomId!,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 4,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Your Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                      hintText: 'Your name',
                    ),
                    textCapitalization: TextCapitalization.words,
                    autofocus: true,
                    onSubmitted: (_) => _joinGame(),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _isJoining ? null : _joinGame,
                    icon: _isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.login),
                    label: Text(_isJoining ? 'Joining...' : 'Join Game'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Default lobby screen for creating or manually joining
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Multiplayer Lobby'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.people,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 20),
              const Text(
                'Play Rummy 500 Online',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Create a game or join a friend',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Your Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Create New Game',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Start a game and share the room code with a friend',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _isCreating || _isJoining ? null : _createGame,
                icon: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.add_circle),
                label: Text(_isCreating ? 'Creating...' : 'Create Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              const SizedBox(height: 30),
              const Divider(),
              const SizedBox(height: 20),
              const Text(
                'Join Existing Game',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter the room code shared by your friend',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _roomCodeController,
                decoration: const InputDecoration(
                  labelText: 'Room Code',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                  hintText: 'e.g. ABC123',
                ),
                textCapitalization: TextCapitalization.characters,
                maxLength: 6,
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: _isCreating || _isJoining ? null : _joinGame,
                icon: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.login),
                label: Text(_isJoining ? 'Joining...' : 'Join Game'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
