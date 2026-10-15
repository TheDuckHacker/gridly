import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/pixel_theme.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'avatar_editor_screen.dart';

/// Editar perfil: nombre, bio y foto real o avatar pixel.
class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late final _name = TextEditingController(text: AppState.I.username);
  late final _bio = TextEditingController(text: AppState.I.bio);
  String? _photo = AppState.I.photoPath;

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final x = await ImagePicker().pickImage(source: source, maxWidth: 512);
      if (x != null && mounted) setState(() => _photo = x.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Px.panelLight,
          content: Text('No se pudo abrir: $e', style: Px.body),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return Scaffold(
      appBar: const PixelAppBar(title: 'EDITAR PERFIL', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: AvatarBadge(
              config: s.avatar,
              size: 110,
              rgb: true,
              animate: true,
              photo: _photo != null ? FileImage(File(_photo!)) : null,
            ),
          ),
          const SizedBox(height: 14),
          Text('FOTO DE PERFIL', style: Px.title(8, Px.textDim)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'CÁMARA',
                  small: true,
                  glyph: PixelGlyphKind.camera,
                  color: Px.panelLight,
                  textColor: Px.text,
                  onPressed: () => _pickPhoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelButton(
                  label: 'GALERÍA',
                  small: true,
                  glyph: PixelGlyphKind.gallery,
                  color: Px.panelLight,
                  textColor: Px.text,
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelButton(
                  label: 'AVATAR',
                  small: true,
                  glyph: PixelGlyphKind.face,
                  color: _photo == null ? Px.accent : Px.panelLight,
                  textColor: _photo == null ? Px.bg : Px.text,
                  onPressed: () => setState(() => _photo = null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          PixelButton(
            label: 'EDITAR AVATAR PIXEL',
            small: true,
            glyph: PixelGlyphKind.edit,
            color: Px.accentDark,
            textColor: Px.text,
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AvatarEditorScreen(),
                  ),
                ),
          ),
          const SizedBox(height: 18),
          Text('BANNER', style: Px.title(8, Px.textDim)),
          const SizedBox(height: 6),
          Text(
            'Solo aquí puedes poner foto o GIF en el banner.',
            style: Px.bodyDim,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'FOTO',
                  small: true,
                  glyph: PixelGlyphKind.image,
                  color: Px.panelLight,
                  textColor: Px.text,
                  onPressed: () async {
                    final x = await ImagePicker().pickImage(
                      source: ImageSource.gallery,
                      maxWidth: 1280,
                    );
                    if (x != null) s.setBannerGif(x.path);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelButton(
                  label: 'GIF',
                  small: true,
                  glyph: PixelGlyphKind.image,
                  color: Px.panelLight,
                  textColor: Px.text,
                  onPressed: () {
                    s.setBannerGif(
                      'https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif',
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: PixelButton(
                  label: 'QUITAR',
                  small: true,
                  color: Px.panelLight,
                  textColor: Px.text,
                  onPressed: () => s.setBannerGif(null),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('NOMBRE DE USUARIO', style: Px.title(8, Px.textDim)),
          const SizedBox(height: 6),
          _field(_name),
          const SizedBox(height: 14),
          Text('BIO', style: Px.title(8, Px.textDim)),
          const SizedBox(height: 6),
          _field(_bio, lines: 3),
          const SizedBox(height: 22),
          PixelButton(
            label: 'GUARDAR',
            glyph: PixelGlyphKind.save,
            onPressed: () {
              s.setUsername(
                _name.text.trim().isEmpty ? s.username : _name.text.trim(),
              );
              s.setBio(_bio.text.trim());
              s.setPhoto(_photo);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, {int lines = 1}) => TextField(
    controller: c,
    maxLines: lines,
    style: Px.body,
    cursorColor: Px.accent,
    decoration: InputDecoration(
      isDense: true,
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
  );
}
