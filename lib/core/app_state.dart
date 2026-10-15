import 'package:flutter/foundation.dart';

import '../widgets/pixel_avatar.dart';
import 'media.dart';
import 'mock_data.dart';
import 'room.dart';

/// Estado global de la red social (demo).
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState I = AppState._();

  String username = 'viajero';

  /// Pestaña que la barra inferior debe abrir (la consume [HomeShell]).
  int? _tabRequest;

  void requestTab(int index) {
    _tabRequest = index;
    notifyListeners();
  }

  int? takeTabRequest() {
    final v = _tabRequest;
    _tabRequest = null;
    return v;
  }
  String phone = '';
  String bio = 'Gamer · pixel artist · café ☕';
  AvatarConfig avatar = const AvatarConfig(
    skin: 1,
    hair: 6,
    hairStyle: 1,
    shirt: 5,
    pants: 0,
    shoes: 1,
    accessory: 2,
  );

  /// Cuenta demo actual (null = viajero custom).
  String? demoAccountId;

  /// Guarda el look propio al cambiar a otra cuenta demo.
  AvatarConfig? _savedAvatar;
  String? _savedBio;
  String? _savedUsername;

  String? photoPath;
  String? bannerGif;
  bool get usesPhoto => photoPath != null;

  RoomConfig room = MockRooms.mine;

  /// Llamada activa (sigue en segundo plano al navegar).
  String? callWith;
  bool callIsVideo = false;
  bool muted = false;
  bool speakerOn = true;
  bool cameraOn = true;

  /// Amigos confirmados (como Instagram/Facebook, no “servidores”).
  final Set<String> friends = {'nova', 'byte', 'kael'};

  /// Te enviaron solicitud.
  final Set<String> friendRequestsIn = {'mara', 'zed'};

  /// Tú enviaste solicitud.
  final Set<String> friendRequestsOut = {'pixelpau'};

  final Set<String> likedPosts = {};
  final Set<String> likedClips = {};
  final Set<String> savedPosts = {};
  final Set<String> savedClips = {};
  final Set<String> repostedPosts = {};
  final Set<String> following = {'nova', 'byte', 'kael', 'mara'};

  /// Quién te sigue a ti (demo).
  final Set<String> followers = {'nova', 'zed', 'pixelpau', 'mara'};

  final Set<String> subscribedTo = {};
  final Set<String> viewedStories = {};
  int unreadDms = 2;

  final List<Post> myPosts = [];
  final List<Story> myStories = [];

  /// Looks del closet (Sims).
  final List<OutfitLook> closetLooks = [
    const OutfitLook(
      'Casual gamer',
      AvatarConfig(
        skin: 1,
        hair: 6,
        hairStyle: 1,
        shirt: 5,
        pants: 0,
        shoes: 1,
        accessory: 2,
      ),
    ),
    const OutfitLook(
      'RGB fit',
      AvatarConfig(
        skin: 1,
        hair: 7,
        hairStyle: 2,
        shirt: 8,
        pants: 7,
        shoes: 4,
        accessory: 3,
      ),
    ),
    const OutfitLook(
      'Street',
      AvatarConfig(
        skin: 2,
        hair: 0,
        hairStyle: 0,
        shirt: 1,
        pants: 1,
        shoes: 2,
        accessory: 1,
      ),
    ),
  ];

  /// Amigos invitados a tu habitación ahora.
  final Set<String> roomInvites = {};

  List<Story> get allStories => [...myStories, ...Mock.stories];

  bool isFriend(String user) => friends.contains(user);
  bool hasIncomingRequest(String user) => friendRequestsIn.contains(user);
  bool hasOutgoingRequest(String user) => friendRequestsOut.contains(user);

  List<String> get onlineFriends =>
      friends
          .where(
            (n) =>
                Mock.users[n]?.status == PresenceStatus.online ||
                Mock.users[n]?.status == PresenceStatus.idle,
          )
          .toList();

  void setUsername(String name) {
    username = name;
    notifyListeners();
  }

  void setPhone(String value) {
    phone = value.trim();
    notifyListeners();
  }

  void setBannerGif(String? url) {
    bannerGif = url;
    notifyListeners();
  }

  void setBio(String value) {
    bio = value;
    notifyListeners();
  }

  /// Cambia a una cuenta demo (nova, byte…) o vuelve a viajero.
  void switchDemoAccount(String? accountId) {
    if (accountId == null || accountId == 'viajero') {
      if (_savedAvatar != null) avatar = _savedAvatar!;
      if (_savedBio != null) bio = _savedBio!;
      username = _savedUsername ?? 'viajero';
      demoAccountId = null;
      _savedAvatar = null;
      _savedBio = null;
      _savedUsername = null;
      notifyListeners();
      return;
    }
    final u = Mock.users[accountId];
    if (u == null) return;
    if (demoAccountId == null) {
      _savedAvatar = avatar;
      _savedBio = bio;
      _savedUsername = username;
    }
    demoAccountId = accountId;
    username = u.name;
    avatar = u.avatar;
    bio = u.bio;
    // Como esa cuenta, eres amigo de viajero y de otros.
    friends
      ..clear()
      ..addAll(Mock.users.keys.where((k) => k != accountId).take(4));
    following
      ..clear()
      ..addAll(friends);
    followers
      ..clear()
      ..addAll(Mock.users.keys.where((k) => k != accountId).take(3));
    friendRequestsIn.clear();
    friendRequestsOut.clear();
    notifyListeners();
  }

  void setAvatar(AvatarConfig config) {
    avatar = config;
    notifyListeners();
  }

  void wearOutfit(AvatarConfig config) => setAvatar(config);

  void saveClosetLook(String name, AvatarConfig config) {
    final label =
        name.trim().isEmpty ? 'Look ${closetLooks.length + 1}' : name.trim();
    closetLooks.insert(0, OutfitLook(label, config));
    notifyListeners();
  }

  void deleteClosetLook(int index) {
    if (index < 0 || index >= closetLooks.length) return;
    closetLooks.removeAt(index);
    notifyListeners();
  }

  /// Invitar amigo a tu habitación (solo amigos).
  bool inviteToRoom(String user) {
    if (!friends.contains(user)) return false;
    roomInvites.add(user);
    notifyListeners();
    return true;
  }

  void setPhoto(String? path) {
    photoPath = path;
    notifyListeners();
  }

  void setRoom(RoomConfig config) {
    room = config;
    notifyListeners();
  }

  /// Peer de la llamada (username) cuando es 1 a 1.
  String? callPeerKey;

  void startCall(String with_, {bool video = false}) {
    callWith = with_;
    callIsVideo = video;
    muted = false;
    speakerOn = true;
    cameraOn = video;
    callPeerKey = _resolveUserKey(with_);
    final peer = callPeerKey;
    if (peer != null && friends.contains(peer)) {
      roomInvites.add(peer);
    }
    notifyListeners();
  }

  void endCall() {
    callPeerKey = null;
    callWith = null;
    notifyListeners();
  }

  /// Resuelve nombre mostrado → key de Mock.users.
  String? _resolveUserKey(String peer) {
    final k = peer.toLowerCase().trim();
    if (Mock.users.containsKey(k)) return k;
    for (final e in Mock.users.entries) {
      if (e.value.name.toLowerCase() == k) return e.key;
    }
    return null;
  }

  String? resolveUserKey(String peer) => _resolveUserKey(peer);

  void toggleMute() {
    muted = !muted;
    notifyListeners();
  }

  void toggleSpeaker() {
    speakerOn = !speakerOn;
    notifyListeners();
  }

  void toggleCamera() {
    cameraOn = !cameraOn;
    notifyListeners();
  }

  void sendFriendRequest(String user) {
    if (friends.contains(user) || friendRequestsOut.contains(user)) return;
    if (friendRequestsIn.contains(user)) {
      acceptFriend(user);
      return;
    }
    friendRequestsOut.add(user);
    notifyListeners();
  }

  /// Busca un usuario demo por número (solo dígitos).
  String? findUserByPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return null;
    for (final e in Mock.users.entries) {
      final p = e.value.phone.replaceAll(RegExp(r'\D'), '');
      if (p == digits || p.endsWith(digits) || digits.endsWith(p)) {
        return e.key;
      }
    }
    return null;
  }

  /// Agrega contacto / solicitud de amistad por celular.
  /// Devuelve: ok | not_found | self | already
  String addByPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final mine = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8) return 'short';
    if (mine.isNotEmpty && (digits == mine || digits.endsWith(mine))) {
      return 'self';
    }
    final user = findUserByPhone(digits);
    if (user == null) return 'not_found';
    if (friends.contains(user)) return 'already';
    sendFriendRequest(user);
    ensureDmThread(user);
    return 'ok';
  }

  void acceptFriend(String user) {
    friendRequestsIn.remove(user);
    friendRequestsOut.remove(user);
    friends.add(user);
    following.add(user);
    notifyListeners();
  }

  void rejectFriend(String user) {
    friendRequestsIn.remove(user);
    notifyListeners();
  }

  void cancelFriendRequest(String user) {
    friendRequestsOut.remove(user);
    notifyListeners();
  }

  void removeFriend(String user) {
    friends.remove(user);
    following.remove(user);
    roomInvites.remove(user);
    notifyListeners();
  }

  void toggleLikePost(String id) {
    likedPosts.contains(id) ? likedPosts.remove(id) : likedPosts.add(id);
    notifyListeners();
  }

  void toggleLikeClip(String id) {
    likedClips.contains(id) ? likedClips.remove(id) : likedClips.add(id);
    notifyListeners();
  }

  void toggleSavePost(String id) {
    savedPosts.contains(id) ? savedPosts.remove(id) : savedPosts.add(id);
    notifyListeners();
  }

  void toggleSaveClip(String id) {
    savedClips.contains(id) ? savedClips.remove(id) : savedClips.add(id);
    notifyListeners();
  }

  void toggleRepost(String id) {
    Post? post;
    for (final p in [...Mock.posts, ...myPosts]) {
      if (p.id == id) {
        post = p;
        break;
      }
    }
    if (repostedPosts.contains(id)) {
      repostedPosts.remove(id);
      if (post != null) post.reposts = (post.reposts - 1).clamp(0, 999999);
    } else {
      repostedPosts.add(id);
      if (post != null) post.reposts += 1;
    }
    notifyListeners();
  }

  void toggleFollow(String user) {
    if (user == username) return;
    if (following.contains(user)) {
      following.remove(user);
    } else {
      following.add(user);
      // Demo: al seguir, a veces te siguen de vuelta.
      if (!followers.contains(user) && user.hashCode.isEven) {
        followers.add(user);
      }
    }
    notifyListeners();
  }

  /// Contadores reales para el perfil propio.
  int get postsCount => myPosts.length + Mock.posts.where((p) => p.author == username).length;
  int get clipsCount => Mock.clips.where((c) => c.author == username).length;
  int get followingCount => following.length;
  int get followersCount => followers.length;
  int get friendsCount => friends.length;

  /// true si se pudo enviar (solo amigos).
  bool trySendDm(String user, String text) {
    if (!friends.contains(user)) return false;
    sendDm(user, text);
    return true;
  }

  void toggleSubscribe(String user) {
    subscribedTo.contains(user)
        ? subscribedTo.remove(user)
        : subscribedTo.add(user);
    notifyListeners();
  }

  void markStoryViewed(String author) {
    viewedStories.add(author);
    notifyListeners();
  }

  void publishStory({
    required String caption,
    String filter = 'Normal',
    double hue = 200,
    String? imageUrl,
  }) {
    myStories.insert(
      0,
      Story(
        author: username,
        caption: caption.isEmpty ? 'mi estado ✨' : caption,
        hue: hue,
        filter: filter,
        ago: 'ahora',
        imageUrl: imageUrl,
      ),
    );
    notifyListeners();
  }

  void addComment(String postId, String text) {
    final list = Mock.postComments.putIfAbsent(postId, () => []);
    list.insert(0, Comment(username, text, 'ahora'));
    for (final p in [...Mock.posts, ...myPosts]) {
      if (p.id == postId) {
        p.comments += 1;
        break;
      }
    }
    notifyListeners();
  }

  /// Publicar foto o clip.
  ///
  /// - `mediaUrl`: link de internet (imagen para foto, MP4/WebM para clip).
  /// - `localPath`: foto tomada/elegida en el dispositivo.
  void publishPost({
    required String caption,
    required String filter,
    double hue = 160,
    bool asClip = false,
    String? mediaUrl,
    String? localPath,
  }) {
    final id = 'mine_${DateTime.now().millisecondsSinceEpoch}';
    final text =
        caption.isEmpty ? (asClip ? 'nuevo clip 🎬' : 'nuevo post') : caption;
    final url =
        (mediaUrl != null && MediaEnv.isUrl(mediaUrl)) ? mediaUrl.trim() : null;
    if (asClip) {
      // Video local (file://) o asset demo; si no hay, un clip de ejemplo.
      final clipUri = url ??
          (localPath != null
              ? MediaEnv.playableUri(
                  localPath.replaceAll('\\', '/').startsWith('/')
                      ? 'file://${localPath.replaceAll('\\', '/')}'
                      : 'file:///${localPath.replaceAll('\\', '/')}',
                )
              : MediaEnv.randomVideo());
      Mock.clips.insert(
        0,
        Clip(
          id: id,
          author: username,
          caption: text,
          song: '$username · demo track',
          likes: 0,
          comments: 0,
          shares: 0,
          hue: hue,
          speed: 1,
          fire: false,
          videoUrl: clipUri,
        ),
      );
      // También deja rastro en perfil como post.
    }
    myPosts.insert(
      0,
      Post(
        id: id,
        author: username,
        caption: text,
        likes: 0,
        comments: 0,
        hue: hue,
        filter: filter,
        ago: 'ahora',
        // Un link de video no se muestra como foto en el feed.
        imageUrl: (url != null && !MediaEnv.looksLikeVideo(url)) ? url : null,
        localPath: localPath,
      ),
    );
    Mock.postComments[id] = [];
    notifyListeners();
  }

  void sendDm(
    String user,
    String text, {
    String? localPath,
    String? sticker,
  }) {
    // Chat solo entre amigos. Solicitudes viven en AMIGOS → PEDIDOS.
    if (!friends.contains(user)) return;
    ensureDmThread(user);
    DmThread? thread;
    for (final t in Mock.dms) {
      if (t.user == user) {
        thread = t;
        break;
      }
    }
    if (thread == null) return;
    final now = DateTime.now();
    final time =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final msg = Message(
      username,
      text,
      time,
      localPath: localPath,
      sticker: sticker,
    );
    thread.messages.add(msg);
    thread.preview =
        sticker != null
            ? '✦ sticker'
            : (localPath != null ? '📷 foto' : text);
    thread.time = time;
    Mock.dms
      ..remove(thread)
      ..insert(0, thread);
    notifyListeners();

    Future<void>.delayed(const Duration(milliseconds: 1400), () {
      if (!friends.contains(user)) return;
      final reply = Message(user, _autoReply(user, text), time);
      final t = Mock.dms.firstWhere((d) => d.user == user);
      t.messages.add(reply);
      t.preview = reply.text;
      t.unread += 1;
      unreadDms += 1;
      notifyListeners();
    });
  }

  /// Crea el hilo si no existe (para poder escribirle a un amigo nuevo).
  void ensureDmThread(String user) {
    for (final t in Mock.dms) {
      if (t.user == user) return;
    }
    Mock.dms.insert(0, DmThread(user: user, preview: '', time: 'ahora'));
  }

  void openDm(String user) {
    if (friends.contains(user)) ensureDmThread(user);
    DmThread? t;
    for (final d in Mock.dms) {
      if (d.user == user) {
        t = d;
        break;
      }
    }
    if (t != null && t.unread > 0) {
      unreadDms = (unreadDms - t.unread).clamp(0, 999);
      t.unread = 0;
      notifyListeners();
    }
  }

  String _autoReply(String user, String text) {
    final lower = text.toLowerCase();
    if (user == 'byte') return 'beep. recibido: "$text" 🤖';
    if (lower.contains('hola') || lower.contains('hey')) {
      return 'hola!! qué tal ✨';
    }
    if (lower.contains('cuarto') ||
        lower.contains('habitaci') ||
        lower.contains('reun')) {
      return 'dale, nos vemos en tu habitación 🏠';
    }
    if (lower.contains('llam') || lower.contains('video')) {
      return 'dale, te llamo en un toque 📞';
    }
    return 'jajaja sí · te leo';
  }
}
