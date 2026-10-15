import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/media.dart';
import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'filters.dart';

/// Cámara / galería estilo TikTok → filtro → publicar.
class CameraScreen extends StatefulWidget {
  const CameraScreen({
    super.key,
    this.asClip = false,
    this.openGallery = false,
  });

  final bool asClip;
  final bool openGallery;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  final _caption = TextEditingController();
  XFile? _file;
  bool _isVideoFile = false;
  String _filter = 'Normal';
  bool _publishing = false;
  bool _done = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _pick(
        widget.openGallery ? ImageSource.gallery : ImageSource.camera,
      );
    });
  }

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final XFile? f;
      if (widget.asClip) {
        f = await _picker.pickVideo(
          source: source,
          maxDuration: const Duration(seconds: 60),
        );
      } else {
        f = await _picker.pickImage(
          source: source,
          maxWidth: 1280,
          imageQuality: 85,
        );
      }
      if (f != null && mounted) {
        setState(() {
          _file = f;
          _isVideoFile = widget.asClip;
        });
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _publish() async {
    if (_file == null) return;
    setState(() => _publishing = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    String? mediaUrl;
    String? localPath = _file!.path;
    if (widget.asClip) {
      // Video del dispositivo → file:// ; si no hay archivo usable, demo asset.
      final path = _file!.path.replaceAll('\\', '/');
      mediaUrl = path.startsWith('/') ? 'file://$path' : 'file:///$path';
      // En Windows a veces el path ya es usable; fallback a clip demo.
      if (!File(_file!.path).existsSync()) {
        mediaUrl = MediaEnv.randomVideo();
        localPath = null;
      }
    }

    AppState.I.publishPost(
      caption: _caption.text.trim(),
      filter: _filter,
      hue: 160 + Random().nextDouble() * 80,
      asClip: widget.asClip,
      mediaUrl: mediaUrl,
      localPath: widget.asClip ? null : localPath,
    );
    if (!mounted) return;
    setState(() {
      _publishing = false;
      _done = true;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PixelAppBar(
        title: widget.asClip ? 'NUEVO CLIP' : 'NUEVA FOTO',
        showBack: true,
        actions: [
          if (_file != null)
            IconButton(
              onPressed: () => setState(() => _file = null),
              icon: PixelGlyph(
                kind: PixelGlyphKind.refresh,
                color: Px.text,
                size: 18,
              ),
            ),
        ],
      ),
      body: _file == null ? _pickerPane() : _previewPane(),
    );
  }

  Widget _pickerPane() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Expanded(
            child: PixelPanel(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_picking)
                    CircularProgressIndicator(color: Px.accent)
                  else
                    PixelGlyph(
                      kind: widget.asClip
                          ? PixelGlyphKind.video
                          : PixelGlyphKind.camera,
                      size: 48,
                      color: Px.accent,
                    ),
                  const SizedBox(height: 18),
                  Text(
                    _picking
                        ? 'ABRIENDO…'
                        : (widget.asClip ? 'GRABA O ELIGE VIDEO' : 'TOMA O ELIGE FOTO'),
                    style: Px.title(9),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.asClip
                        ? 'Cámara o galería de videos'
                        : 'Cámara o galería de fotos',
                    style: Px.bodyDim,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  PixelButton(
                    label: widget.asClip ? 'GRABAR' : 'ABRIR CÁMARA',
                    glyph: widget.asClip
                        ? PixelGlyphKind.record
                        : PixelGlyphKind.camera,
                    color: widget.asClip ? Px.danger : Px.accent,
                    onPressed: () => _pick(ImageSource.camera),
                  ),
                  const SizedBox(height: 12),
                  PixelButton(
                    label: 'GALERÍA',
                    glyph: PixelGlyphKind.gallery,
                    color: Px.accentDim,
                    onPressed: () => _pick(ImageSource.gallery),
                  ),
                  if (widget.asClip) ...[
                    const SizedBox(height: 12),
                    PixelButton(
                      label: 'USAR CLIP DEMO',
                      glyph: PixelGlyphKind.play,
                      color: Px.magenta,
                      onPressed: () {
                        AppState.I.publishPost(
                          caption: _caption.text.trim().isEmpty
                              ? 'mi clip 🎬'
                              : _caption.text.trim(),
                          filter: _filter,
                          asClip: true,
                          mediaUrl: MediaEnv.randomVideo(),
                        );
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewPane() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        PixelPanel(
          padding: EdgeInsets.zero,
          child: AspectRatio(
            aspectRatio: widget.asClip ? 9 / 14 : 1,
            child: PixelFilter(
              name: _filter,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_isVideoFile)
                    ColoredBox(
                      color: Colors.black,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PixelGlyph(
                              kind: PixelGlyphKind.play,
                              size: 64,
                              color: Px.accent,
                            ),
                            const SizedBox(height: 10),
                            Text('VIDEO LISTO', style: Px.label(8, Px.text)),
                            const SizedBox(height: 6),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _file!.name,
                                style: Px.bodyDim,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Image.file(File(_file!.path), fit: BoxFit.cover),
                  IgnorePointer(
                    child: CustomPaint(painter: _RgbCornerPainter()),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      color: Px.bg.withValues(alpha: 0.7),
                      child: Text(
                        _filter.toUpperCase(),
                        style: Px.label(6, Px.accent),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: PixelAvatar(config: AppState.I.avatar, size: 36),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!widget.asClip) ...[
          Text('FILTROS', style: Px.title(8)),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PixelFilter.names.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final n = PixelFilter.names[i];
                return PixelChip(
                  label: n.toUpperCase(),
                  selected: _filter == n,
                  onTap: () => setState(() => _filter = n),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],
        Text('DESCRIPCIÓN', style: Px.title(8)),
        const SizedBox(height: 8),
        TextField(
          controller: _caption,
          maxLines: 2,
          style: Px.body,
          cursorColor: Px.accent,
          decoration: InputDecoration(
            hintText: widget.asClip ? 'Describe tu clip…' : '¿Qué estás compartiendo?',
            hintStyle: Px.bodyDim,
            filled: true,
            fillColor: Px.panel,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Px.border, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: Px.accent, width: 2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        PixelButton(
          label: _done
              ? '¡PUBLICADO!'
              : (_publishing
                  ? 'PUBLICANDO...'
                  : (widget.asClip ? 'PUBLICAR CLIP' : 'PUBLICAR')),
          glyph: _done ? PixelGlyphKind.check : PixelGlyphKind.send,
          enabled: !_publishing && !_done,
          onPressed: _publish,
        ),
      ],
    );
  }
}

class _RgbCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const t = 3.0;
    final colors = Px.rgb;
    void corner(double x, double y, int start) {
      for (var i = 0; i < 8; i++) {
        final p = Paint()..color = colors[(start + i) % colors.length];
        canvas.drawRect(Rect.fromLTWH(x + i * t, y, t, t), p);
        canvas.drawRect(Rect.fromLTWH(x, y + i * t, t, t), p);
      }
    }

    corner(0, 0, 0);
    corner(size.width - 8 * t, 0, 2);
    corner(0, size.height - 8 * t, 4);
    corner(size.width - 8 * t, size.height - 8 * t, 6);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
