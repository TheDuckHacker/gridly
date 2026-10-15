import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'filters.dart';

/// Crear historia / estado (sin pegar links).
class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final _picker = ImagePicker();
  final _caption = TextEditingController();
  String _filter = 'Normal';
  double _hue = 180;
  String? _localPath;

  @override
  void dispose() {
    _caption.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final f = await _picker.pickImage(
      source: source,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (f != null && mounted) setState(() => _localPath = f.path);
  }

  void _publish() {
    // Si hay foto local, la publicamos como post+story caption;
    // la historia usa color/filtro; la foto se guarda también en el feed.
    if (_localPath != null) {
      AppState.I.publishPost(
        caption: _caption.text.trim().isEmpty
            ? 'mi historia ✨'
            : _caption.text.trim(),
        filter: _filter,
        hue: _hue,
        localPath: _localPath,
      );
    }
    AppState.I.publishStory(
      caption: _caption.text.trim(),
      filter: _filter,
      hue: _hue,
      imageUrl: null,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return Scaffold(
      appBar: const PixelAppBar(title: 'TU HISTORIA', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          AspectRatio(
            aspectRatio: 9 / 14,
            child: PixelFilter(
              name: _filter,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_localPath != null)
                    Image.file(File(_localPath!), fit: BoxFit.cover)
                  else
                    ColoredBox(
                      color: HSVColor.fromAHSV(1, _hue, 0.45, 0.35).toColor(),
                    ),
                  if (_localPath != null)
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC000000)],
                        ),
                      ),
                    ),
                  Align(
                    alignment: _localPath != null
                        ? const Alignment(0, 0.8)
                        : Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_localPath == null) ...[
                          PixelAvatar(config: s.avatar, size: 96),
                          const SizedBox(height: 16),
                        ],
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            _caption.text.isEmpty
                                ? 'Escribe tu estado…'
                                : _caption.text,
                            style: Px.title(10, Px.text),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'CÁMARA',
                  small: true,
                  glyph: PixelGlyphKind.camera,
                  color: Px.magenta,
                  onPressed: () => _pick(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelButton(
                  label: 'GALERÍA',
                  small: true,
                  glyph: PixelGlyphKind.gallery,
                  color: Px.accentDim,
                  onPressed: () => _pick(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('FILTRO', style: Px.title(8)),
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
          if (_localPath == null) ...[
            const SizedBox(height: 14),
            Text('COLOR', style: Px.title(8)),
            Slider(
              value: _hue,
              min: 0,
              max: 360,
              activeColor: Px.accent,
              onChanged: (v) => setState(() => _hue = v),
            ),
          ],
          TextField(
            controller: _caption,
            maxLines: 2,
            style: Px.body,
            cursorColor: Px.accent,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '¿Qué estás haciendo?',
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
            label: 'PUBLICAR HISTORIA',
            glyph: PixelGlyphKind.sparkle,
            onPressed: _publish,
          ),
        ],
      ),
    );
  }
}
