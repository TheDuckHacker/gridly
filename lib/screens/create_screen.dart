import 'package:flutter/material.dart';

import '../core/pixel_theme.dart';
import '../widgets/pixel_ui.dart';
import 'camera_screen.dart';
import 'create_story_screen.dart';

/// Crear contenido estilo TikTok: grabar / galería / historia.
/// Sin pegar links.
class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});

  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  int _mode = 1; // 0 foto, 1 video (default TikTok), 2 historia

  Future<void> _openCamera({required bool fromGallery}) async {
    if (_mode == 2) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const CreateStoryScreen()),
      );
      if (ok == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Historia publicada', style: Px.body),
            backgroundColor: Px.panelLight,
          ),
        );
      }
      return;
    }
    final ok = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CameraScreen(
          asClip: _mode == 1,
          openGallery: fromGallery,
        ),
      ),
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mode == 1 ? 'Clip publicado · míralo en CLIPS' : 'Foto publicada',
            style: Px.body,
          ),
          backgroundColor: Px.panelLight,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isVideo = _mode == 1;
    final isStory = _mode == 2;
    return Scaffold(
      backgroundColor: Px.bg,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  Text('CREAR', style: Px.title(10)),
                  const Spacer(),
                  Text(
                    isStory
                        ? 'HISTORIA'
                        : (isVideo ? 'CLIP' : 'FOTO'),
                    style: Px.label(7, Px.accent),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Px.panel,
                    border: Border.all(color: Px.border, width: 2),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Fondo tipo visor de cámara.
                      CustomPaint(painter: _CamGridPainter()),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PixelRoundIcon(
                              kind: isStory
                                  ? PixelGlyphKind.sparkle
                                  : (isVideo
                                      ? PixelGlyphKind.video
                                      : PixelGlyphKind.camera),
                              size: 72,
                              glyphSize: 28,
                              color: Px.accent,
                              borderColor: Px.accent,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              isStory
                                  ? 'TU HISTORIA'
                                  : (isVideo
                                      ? 'GRABA UN CLIP'
                                      : 'TOMA UNA FOTO'),
                              style: Px.title(9),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 28),
                              child: Text(
                                isStory
                                    ? 'Estados que duran 24 h en el feed'
                                    : (isVideo
                                        ? 'Graba o elige un video\nde tu galería y publícalo'
                                        : 'Abre la cámara o elige de la galería'),
                                style: Px.bodyDim,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Anillo de grabar (centro abajo).
                      Positioned(
                        bottom: 28,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _SideBtn(
                              kind: PixelGlyphKind.gallery,
                              label: 'GALERÍA',
                              onTap: () => _openCamera(fromGallery: true),
                            ),
                            GestureDetector(
                              onTap: () => _openCamera(fromGallery: false),
                              child: Container(
                                width: 78,
                                height: 78,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isVideo ? Px.danger : Px.accent,
                                    width: 5,
                                  ),
                                ),
                                child: Container(
                                  margin: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isVideo ? Px.danger : Px.accent,
                                  ),
                                  child: Center(
                                    child: PixelGlyph(
                                      kind: isStory
                                          ? PixelGlyphKind.sparkle
                                          : (isVideo
                                              ? PixelGlyphKind.record
                                              : PixelGlyphKind.camera),
                                      color: Px.bg,
                                      size: isVideo ? 28 : 22,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            _SideBtn(
                              kind: PixelGlyphKind.switchCam,
                              label: 'CÁMARA',
                              onTap: () => _openCamera(fromGallery: false),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Selector inferior: FOTO · VIDEO · HISTORIA (estilo TikTok).
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ModeTab(
                    label: 'FOTO',
                    selected: _mode == 0,
                    onTap: () => setState(() => _mode = 0),
                  ),
                  _ModeTab(
                    label: 'VIDEO',
                    selected: _mode == 1,
                    onTap: () => setState(() => _mode = 1),
                  ),
                  _ModeTab(
                    label: 'HISTORIA',
                    selected: _mode == 2,
                    onTap: () => setState(() => _mode = 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          children: [
            Text(
              label,
              style: Px.label(8, selected ? Px.accent : Px.textDim),
            ),
            const SizedBox(height: 4),
            Container(
              width: 36,
              height: 3,
              color: selected ? Px.accent : Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}

class _SideBtn extends StatelessWidget {
  const _SideBtn({
    required this.kind,
    required this.label,
    required this.onTap,
  });
  final PixelGlyphKind kind;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          PixelRoundIcon(kind: kind, size: 44, color: Px.text),
          const SizedBox(height: 6),
          Text(label, style: Px.label(5, Px.textDim)),
        ],
      ),
    );
  }
}

class _CamGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF0A1210);
    canvas.drawRect(Offset.zero & size, bg);
    final line = Paint()
      ..color = Px.border.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), line);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
