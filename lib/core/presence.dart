import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../widgets/pixel_avatar.dart';
import 'mock_data.dart';

/// Miembro presente en una sala demo (multiplayer local simulado).
class PresenceMember {
  PresenceMember({
    required this.id,
    required this.avatar,
    this.x = 0.5,
    this.y = 0.65,
    this.bubble,
    this.isBot = false,
  });

  final String id;
  AvatarConfig avatar;
  double x;
  double y;
  String? bubble;
  final bool isBot;
  DateTime lastSeen = DateTime.now();
}

/// Presencia compartida del demo: varios avatares en la misma habitación.
/// (Simula online sin backend; listo para conectar Firebase/Supabase después.)
class PresenceService extends ChangeNotifier {
  PresenceService._();
  static final PresenceService I = PresenceService._();

  static const demoRoomId = 'pixelgram_demo';

  String? activeRoomId;
  final Map<String, PresenceMember> members = {};
  final List<String> joinLog = [];
  final _rng = Random();
  Timer? _botTimer;
  bool doorJustOpened = false;

  int get onlineCount => members.length;
  bool get inRoom => activeRoomId != null;

  void joinRoom({
    required String roomId,
    required String userId,
    required AvatarConfig avatar,
  }) {
    activeRoomId = roomId;
    members[userId] = PresenceMember(
      id: userId,
      avatar: avatar,
      x: 0.45 + _rng.nextDouble() * 0.1,
      y: 0.55 + _rng.nextDouble() * 0.2,
    );
    joinLog.insert(0, '$userId entró · puerta abierta 🚪');
    doorJustOpened = true;
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 1600), () {
      doorJustOpened = false;
      notifyListeners();
    });
  }

  void leaveRoom(String userId) {
    if (members.remove(userId) != null) {
      joinLog.insert(0, '$userId salió');
      notifyListeners();
    }
    if (members.isEmpty) {
      activeRoomId = null;
      _botTimer?.cancel();
      _botTimer = null;
    }
  }

  void leaveAll() {
    members.clear();
    activeRoomId = null;
    _botTimer?.cancel();
    _botTimer = null;
    notifyListeners();
  }

  void move(String userId, double x, double y) {
    final m = members[userId];
    if (m == null) return;
    m.x = x.clamp(0.05, 0.95);
    m.y = y.clamp(0.25, 0.95);
    m.lastSeen = DateTime.now();
    notifyListeners();
  }

  void say(String userId, String text) {
    final m = members[userId];
    if (m == null) return;
    m.bubble = text;
    joinLog.insert(0, '$userId: $text');
    notifyListeners();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (m.bubble == text) {
        m.bubble = null;
        notifyListeners();
      }
    });
  }

  /// Entra amigos demo con “latencia de red” para sentir online.
  void spawnDemoGuests(Iterable<String> friendIds, {int max = 3}) {
    final list = friendIds.where(Mock.users.containsKey).take(max).toList();
    var delay = 800;
    for (final id in list) {
      if (members.containsKey(id)) continue;
      final wait = delay;
      delay += 1200 + _rng.nextInt(800);
      Future<void>.delayed(Duration(milliseconds: wait), () {
        if (activeRoomId == null) return;
        final u = Mock.users[id]!;
        members[id] = PresenceMember(
          id: id,
          avatar: u.avatar,
          x: 0.15 + _rng.nextDouble() * 0.7,
          y: 0.45 + _rng.nextDouble() * 0.4,
          isBot: true,
        );
        joinLog.insert(0, '$id se conectó · online');
        doorJustOpened = true;
        notifyListeners();
        Future<void>.delayed(const Duration(milliseconds: 1400), () {
          doorJustOpened = false;
          notifyListeners();
        });
        say(
          id,
          ['hola! 👋', 'acabo de entrar', '¿qué onda?', 'puerta abierta ✨'][_rng
              .nextInt(4)],
        );
      });
    }
    _botTimer?.cancel();
    _botTimer = Timer.periodic(const Duration(seconds: 4), (_) => _tickBots());
  }

  void inviteFriendNow(String id) {
    if (!Mock.users.containsKey(id) || members.containsKey(id)) return;
    final u = Mock.users[id]!;
    members[id] = PresenceMember(
      id: id,
      avatar: u.avatar,
      x: 0.2 + _rng.nextDouble() * 0.6,
      y: 0.5 + _rng.nextDouble() * 0.3,
      isBot: true,
    );
    joinLog.insert(0, 'Invitaste a $id · puerta abierta 🚪');
    doorJustOpened = true;
    say(id, 'gracias por abrirme!');
    notifyListeners();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      doorJustOpened = false;
      notifyListeners();
    });
    _botTimer ??= Timer.periodic(
      const Duration(seconds: 4),
      (_) => _tickBots(),
    );
  }

  void _tickBots() {
    if (activeRoomId == null) return;
    for (final m in members.values.where((e) => e.isBot)) {
      final r = _rng.nextDouble();
      if (r < 0.55) {
        move(
          m.id,
          0.1 + _rng.nextDouble() * 0.8,
          0.35 + _rng.nextDouble() * 0.55,
        );
      } else if (r < 0.75) {
        say(
          m.id,
          ['jajaja', 'nice fit', 'vamos a call?', '👀', 'ok'][_rng.nextInt(5)],
        );
      }
    }
  }
}
