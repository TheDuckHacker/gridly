import '../widgets/pixel_avatar.dart';

class User {
  const User(
    this.name,
    this.avatar,
    this.status, {
    this.bio = '',
    this.phone = '',
  });
  final String name;
  final AvatarConfig avatar;
  final PresenceStatus status;
  final String bio;

  /// Celular demo (solo dígitos) para agregar amigos como WhatsApp.
  final String phone;
}

class Post {
  Post({
    required this.id,
    required this.author,
    required this.caption,
    required this.likes,
    required this.comments,
    required this.hue,
    this.filter = 'Normal',
    required this.ago,
    this.reposts = 0,
    this.isRepostOf,
    this.imageUrl,
    this.localPath,
  });
  final String id;
  final String author;
  String caption;
  int likes;
  int comments;
  final double hue;
  final String filter;
  final String ago;
  int reposts;
  final String? isRepostOf;

  /// Foto real desde internet (link).
  final String? imageUrl;

  /// Foto tomada/elegida en el dispositivo.
  final String? localPath;

  bool get hasMedia => imageUrl != null || localPath != null;
}

class Clip {
  const Clip({
    required this.id,
    required this.author,
    required this.caption,
    required this.song,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.hue,
    this.speed = 1,
    this.fire = false,
    this.videoUrl,
  });
  final String id;
  final String author;
  final String caption;
  final String song;
  final int likes;
  final int comments;
  final int shares;
  final double hue;
  final double speed;
  final bool fire;

  /// Video real desde internet (link MP4/WebM/HLS).
  final String? videoUrl;
}

class Message {
  const Message(
    this.author,
    this.text,
    this.time, {
    this.localPath,
    this.sticker,
  });
  final String author;
  final String text;
  final String time;

  /// Ruta local de foto adjunta (demo en dispositivo).
  final String? localPath;

  /// Sticker pixel (`heart`, `star`, `sparkle`, …).
  final String? sticker;

  bool get hasImage => localPath != null && localPath!.isNotEmpty;
  bool get hasSticker => sticker != null && sticker!.isNotEmpty;
}

class Comment {
  const Comment(this.author, this.text, this.ago, {this.likes = 0});
  final String author;
  final String text;
  final String ago;
  final int likes;
}

class Story {
  const Story({
    required this.author,
    required this.caption,
    required this.hue,
    this.filter = 'Normal',
    this.ago = 'hace 1 h',
    this.imageUrl,
  });
  final String author;
  final String caption;
  final double hue;
  final String filter;
  final String ago;

  /// Foto real desde internet (link).
  final String? imageUrl;
}

class DmThread {
  DmThread({
    required this.user,
    required this.preview,
    required this.time,
    this.unread = 0,
    List<Message>? messages,
  }) : messages = messages ?? [];
  final String user;
  String preview;
  String time;
  int unread;
  final List<Message> messages;
}

abstract final class Mock {
  static const users = <String, User>{
    'nova': User(
      'nova',
      AvatarConfig(skin: 0, hair: 6, hairStyle: 2, shirt: 3, accessory: 1),
      PresenceStatus.online,
      bio: 'speedrunner · 16 bits de pura energía',
      phone: '5551002001',
    ),
    'byte': User(
      'byte',
      AvatarConfig(skin: 5, hair: 5, hairStyle: 4, shirt: 5, accessory: 4),
      PresenceStatus.online,
      bio: 'robot amigable. beep.',
      phone: '5551002002',
    ),
    'kael': User(
      'kael',
      AvatarConfig(skin: 2, hair: 0, hairStyle: 1, shirt: 2, accessory: 0),
      PresenceStatus.idle,
      bio: 'guitarra + pixel art',
      phone: '5551002003',
    ),
    'mara': User(
      'mara',
      AvatarConfig(skin: 1, hair: 4, hairStyle: 0, shirt: 6, accessory: 3),
      PresenceStatus.dnd,
      bio: 'reina del lobby 👑',
      phone: '5551002004',
    ),
    'pixelpau': User(
      'pixelpau',
      AvatarConfig(skin: 3, hair: 3, hairStyle: 2, shirt: 4, accessory: 2),
      PresenceStatus.offline,
      bio: 'dj en vivo todos los viernes',
      phone: '5551002005',
    ),
    'zed': User(
      'zed',
      AvatarConfig(skin: 4, hair: 1, hairStyle: 3, shirt: 1, accessory: 0),
      PresenceStatus.online,
      bio: 'zombi pero buena onda',
      phone: '5551002006',
    ),
  };

  static final posts = <Post>[
    Post(
      id: 'p1',
      author: 'nova',
      caption: 'Nuevo récord en la ciudad nocturna 🌙 ¿quién lo supera?',
      likes: 1240,
      comments: 86,
      hue: 0,
      ago: 'hace 2 h',
      reposts: 42,
      imageUrl: 'https://picsum.photos/seed/pixelgram-night-city/800/800',
    ),
    Post(
      id: 'p2',
      author: 'kael',
      caption: 'Atardecer con filtro Retro. Hecho desde la app 🎸',
      likes: 532,
      comments: 23,
      hue: 30,
      filter: 'Retro',
      ago: 'hace 5 h',
      reposts: 11,
      imageUrl: 'https://picsum.photos/seed/pixelgram-sunset/800/800',
    ),
    Post(
      id: 'p3',
      author: 'mara',
      caption: 'Mi avatar nuevo con corona. Opinen 👑',
      likes: 2210,
      comments: 140,
      hue: 300,
      filter: 'Game Boy',
      ago: 'ayer',
      reposts: 88,
    ),
    Post(
      id: 'p4',
      author: 'byte',
      caption: 'beep boop. primer post.',
      likes: 97,
      comments: 12,
      hue: 200,
      filter: 'CRT',
      ago: 'ayer',
      reposts: 3,
      imageUrl: 'https://picsum.photos/seed/pixelgram-robot/800/800',
    ),
    Post(
      id: 'p5',
      author: 'zed',
      caption: 'paseo nocturno 🧟 sin filtro',
      likes: 410,
      comments: 31,
      hue: 0,
      ago: 'hace 2 días',
      reposts: 7,
      imageUrl: 'https://picsum.photos/seed/pixelgram-walk/800/800',
    ),
  ];

  static final clips = <Clip>[
    const Clip(
      id: 'c1',
      author: 'pixelpau',
      caption: 'viernes de live 🎧 ven al grupo',
      song: 'Pixel Pau · Night Drive (8-bit)',
      likes: 18400,
      comments: 920,
      shares: 310,
      hue: 0,
      speed: 1.4,
      fire: true,
      videoUrl: 'asset:///assets/videos/clip1.mp4',
    ),
    Clip(
      id: 'c2',
      author: 'nova',
      caption: 'POV: tu avatar cuando subes de nivel #speedrun',
      song: 'nova · Level Up Loop',
      likes: 42100,
      comments: 1800,
      shares: 2400,
      hue: 180,
      speed: 2.2,
      videoUrl: 'asset:///assets/videos/clip2.mp4',
    ),
    Clip(
      id: 'c3',
      author: 'zed',
      caption: 'bailecito de zombi 🧟 #pixeldance',
      song: 'zed · Graveyard Groove',
      likes: 7600,
      comments: 220,
      shares: 90,
      hue: 270,
      speed: 0.8,
      fire: true,
      videoUrl: 'asset:///assets/videos/clip3.mp4',
    ),
    Clip(
      id: 'c4',
      author: 'mara',
      caption: 'la corona pesa 👑 #lobbyqueen',
      song: 'mara · Crown Beat',
      likes: 99000,
      comments: 5200,
      shares: 8100,
      hue: 40,
      speed: 1.1,
      videoUrl: 'asset:///assets/videos/clip4.mp4',
    ),
    Clip(
      id: 'c5',
      author: 'kael',
      caption: 'abejas en el jardín 🐝 #naturaleza',
      song: 'kael · Acoustic Loop',
      likes: 3100,
      comments: 140,
      shares: 60,
      hue: 90,
      speed: 1,
      videoUrl: 'asset:///assets/videos/clip5.mp4',
    ),
    Clip(
      id: 'c6',
      author: 'byte',
      caption: 'mariposa.exe 🦋',
      song: 'byte · Chip Garden',
      likes: 880,
      comments: 40,
      shares: 12,
      hue: 200,
      speed: 1,
      videoUrl: 'asset:///assets/videos/clip6.mp4',
    ),
  ];

  static final postComments = <String, List<Comment>>{
    'p1': [
      const Comment('kael', 'brutal el récord 🔥', 'hace 1 h', likes: 12),
      const Comment('mara', 'yo lo intento mañana 👑', 'hace 50 min', likes: 4),
      const Comment('byte', 'beep. +1 speedrun.', 'hace 20 min'),
    ],
    'p2': [
      const Comment(
        'nova',
        'el filtro Retro queda perfecto',
        'hace 3 h',
        likes: 8,
      ),
      const Comment('zed', 'suena a tema de guitarra eso', 'hace 2 h'),
    ],
    'p3': [
      const Comment('pixelpau', 'corona on point', 'hace 8 h', likes: 30),
      const Comment('nova', 'reina confirmada', 'hace 6 h', likes: 15),
    ],
    'p4': [const Comment('kael', 'bienvenido byte 🤖', 'hace 10 h')],
  };

  static final stories = <Story>[
    const Story(
      author: 'nova',
      caption: 'warmup del speedrun',
      hue: 180,
      filter: 'Neón',
      imageUrl: 'https://picsum.photos/seed/pixelgram-story-nova/720/1280',
    ),
    const Story(
      author: 'kael',
      caption: 'ensayo del tema nuevo',
      hue: 40,
      filter: 'Retro',
      ago: 'hace 3 h',
      imageUrl: 'https://picsum.photos/seed/pixelgram-story-kael/720/1280',
    ),
    const Story(
      author: 'mara',
      caption: 'corona check 👑',
      hue: 300,
      filter: 'Game Boy',
      ago: 'hace 4 h',
    ),
    const Story(
      author: 'byte',
      caption: 'beep · offline mode',
      hue: 200,
      filter: 'CRT',
      ago: 'hace 6 h',
      imageUrl: 'https://picsum.photos/seed/pixelgram-story-byte/720/1280',
    ),
    const Story(
      author: 'zed',
      caption: 'bailecito de prueba',
      hue: 270,
      ago: 'hace 8 h',
    ),
  ];

  static final dms = <DmThread>[
    DmThread(
      user: 'nova',
      preview: '¿vienes a la carrera?',
      time: '22:51',
      unread: 2,
      messages: [
        const Message('nova', 'hola!! listos para el clip?', '22:48'),
        const Message('nova', '¿vienes a la carrera?', '22:51'),
      ],
    ),
    DmThread(
      user: 'kael',
      preview: 'te pasé el loop 8-bit',
      time: '21:10',
      unread: 0,
      messages: [
        const Message('kael', 'oye, te pasé el loop 8-bit', '21:08'),
        const Message('kael', 'te pasé el loop 8-bit', '21:10'),
      ],
    ),
    DmThread(
      user: 'byte',
      preview: 'beep. reunión en 10.',
      time: '18:40',
      unread: 0,
      messages: [const Message('byte', 'beep. reunión en 10.', '18:40')],
    ),
  ];
}
