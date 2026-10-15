import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../core/app_state.dart';
import '../core/pixel_theme.dart';
import '../core/sfx.dart';
import '../game/login_background_game.dart';
import '../widgets/local_image.dart'
    if (dart.library.io) '../widgets/local_image_io.dart';
import '../widgets/pixel_avatar.dart';
import '../widgets/pixel_ui.dart';
import 'avatar_editor_screen.dart';
import 'home_shell.dart';

enum _AuthStep { phone, sending, code, profile }

/// Puerta única: intro + registro estilo WhatsApp
/// (celular → SMS → perfil con avatar).
class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    this.goodbye,
    this.playIntro = false,
  });

  final String? goodbye;
  final bool playIntro;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final LoginBackgroundGame _game;
  final _phoneKey = GlobalKey<FormState>();
  final _codeKey = GlobalKey<FormState>();
  final _profileKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();

  _AuthStep _step = _AuthStep.phone;
  bool _loading = false;
  bool _formVisible = false;
  bool _introDone = false;
  bool _sceneFocus = false;
  late AvatarConfig _draftAvatar;
  String? _draftPhoto;
  final _rng = Random();
  final _picker = ImagePicker();

  late final AnimationController _enterCtrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _wantIntro => widget.playIntro && widget.goodbye == null;

  String get _phoneDigits =>
      _phoneController.text.replaceAll(RegExp(r'\D'), '');

  String get _phonePretty => '+591 $_phoneDigits';

  @override
  void initState() {
    super.initState();
    _introDone = !_wantIntro;
    _draftAvatar = AppState.I.avatar;
    _game = LoginBackgroundGame(
      avatarConfig: _draftAvatar,
      playBrandIntro: _wantIntro,
      onIntroReady: _onIntroReady,
    );
    Sfx.I.init();

    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    );

    _fade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    final bye = widget.goodbye;
    if (bye != null) {
      _sceneFocus = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _game.celebrateGoodbye(bye);
        if (mounted) {
          setState(() => _sceneFocus = false);
          _revealForm();
        }
      });
    } else if (!_wantIntro) {
      Future<void>.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _revealForm();
      });
    }
  }

  void _onIntroReady() {
    if (!mounted) return;
    setState(() => _introDone = true);
    // Form solo cuando la ciudad ya se reveló (nunca encima del splash).
    Future<void>.delayed(const Duration(milliseconds: 420), () {
      if (mounted) _revealForm();
    });
  }

  void _revealForm() {
    if (_formVisible) return;
    setState(() => _formVisible = true);
    _enterCtrl.forward(from: 0);
  }

  void _skipOrTap() {
    if (!_introDone && _wantIntro) _game.skipIntro();
  }

  Future<void> _goStep(_AuthStep next) async {
    await _enterCtrl.reverse();
    if (!mounted) return;
    setState(() {
      _step = next;
      _loading = false;
    });
    _enterCtrl.forward(from: 0);
  }

  Future<void> _submitPhone() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    await Sfx.I.tap();
    if (!(_phoneKey.currentState?.validate() ?? false)) {
      await Sfx.I.error();
      _game.shakeError();
      return;
    }
    setState(() => _loading = true);
    AppState.I.setPhone(_phoneDigits);
    await _goStep(_AuthStep.sending);
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    await Sfx.I.success();
    await _goStep(_AuthStep.code);
  }

  Future<void> _submitCode() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    await Sfx.I.tap();
    if (!(_codeKey.currentState?.validate() ?? false)) {
      await Sfx.I.error();
      _game.shakeError();
      return;
    }
    final code = _codeController.text.trim();
    if (code.length != 6) {
      await Sfx.I.error();
      _game.shakeError();
      return;
    }
    setState(() => _loading = true);
    await Sfx.I.success();
    await _goStep(_AuthStep.profile);
  }

  Future<void> _submitProfile() async {
    if (_loading) return;
    FocusScope.of(context).unfocus();
    await Sfx.I.tap();
    if (!(_profileKey.currentState?.validate() ?? false)) {
      await Sfx.I.error();
      _game.shakeError();
      return;
    }
    final name = _nameController.text.trim();
    setState(() {
      _loading = true;
      _formVisible = false;
      _sceneFocus = true;
    });
    _enterCtrl.value = 0;
    await Sfx.I.success();

    AppState.I.setUsername(name);
    AppState.I.setPhone(_phoneDigits);
    AppState.I.setAvatar(_draftAvatar);
    AppState.I.setPhoto(_draftPhoto);
    _game.avatar.config = _draftAvatar;

    await _game.celebrateLogin(name);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 650),
        pageBuilder: (_, __, ___) => const HomeShell(fromLogin: true),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.06),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final x = await _picker.pickImage(source: source, maxWidth: 512);
      if (x != null && mounted) {
        setState(() => _draftPhoto = x.path);
        await Sfx.I.tap();
      }
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

  Future<void> _editAvatar() async {
    AppState.I.setAvatar(_draftAvatar);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AvatarEditorScreen()),
    );
    if (!mounted) return;
    setState(() {
      _draftAvatar = AppState.I.avatar;
      _draftPhoto = null; // al editar pixel, usa avatar
      _game.avatar.config = _draftAvatar;
    });
  }

  void _useAvatarOnly() {
    setState(() => _draftPhoto = null);
    Sfx.I.tap();
  }

  void _randomizeAvatar() {
    setState(() {
      _draftPhoto = null;
      _draftAvatar = AvatarConfig(
        skin: _rng.nextInt(AvatarParts.skins.length),
        hair: _rng.nextInt(AvatarParts.hairs.length),
        hairStyle: _rng.nextInt(5),
        shirt: _rng.nextInt(AvatarParts.shirts.length),
        pants: _rng.nextInt(AvatarParts.pants.length),
        shoes: _rng.nextInt(AvatarParts.shoes.length),
        accessory: _rng.nextInt(5),
      );
      _game.avatar.config = _draftAvatar;
    });
    Sfx.I.tap();
  }

  void _cycleSkin() {
    setState(() {
      _draftPhoto = null;
      _draftAvatar = _draftAvatar.copyWith(
        skin: (_draftAvatar.skin + 1) % AvatarParts.skins.length,
      );
      _game.avatar.config = _draftAvatar;
    });
    Sfx.I.tap();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final splash = !_introDone && _wantIntro;
    return Scaffold(
      backgroundColor: splash ? const Color(0xFF000000) : Px.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          GameWidget(game: _game),
          if (splash)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _skipOrTap,
                child: const SizedBox.expand(),
              ),
            ),
          if (!_sceneFocus && _introDone)
            SafeArea(
              child: Align(
                // Formulario arriba (debajo del logo GRIDLY).
                alignment: const Alignment(0, -0.38),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 56),
                        IgnorePointer(
                          ignoring: !_formVisible,
                          child: FadeTransition(
                            opacity: _fade,
                            child: SlideTransition(
                              position: _slide,
                              child: PixelPanel(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  18,
                                  16,
                                  16,
                                ),
                                child: _buildStep(),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    return switch (_step) {
      _AuthStep.phone => _phoneStep(),
      _AuthStep.sending => _sendingStep(),
      _AuthStep.code => _codeStep(),
      _AuthStep.profile => _profileStep(),
    };
  }

  Widget _phoneStep() {
    return Form(
      key: _phoneKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu número',
            textAlign: TextAlign.center,
            style: Px.title(10),
          ),
          const SizedBox(height: 6),
          Text(
            'Te enviaremos un SMS con un código',
            textAlign: TextAlign.center,
            style: Px.label(6, Px.textDim),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _BitChip(label: '+591'),
              const SizedBox(width: 8),
              Expanded(
                child: _BitField(
                  controller: _phoneController,
                  hint: 'CELULAR',
                  keyboardType: TextInputType.phone,
                  onFieldSubmitted: (_) => _submitPhone(),
                  validator: (v) {
                    final d = (v ?? '').replaceAll(RegExp(r'\D'), '');
                    if (d.length < 8) return 'Mínimo 8 dígitos';
                    return null;
                  },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          PixelButton(
            label: _loading ? '...' : 'CONTINUAR',
            glyph: PixelGlyphKind.check,
            enabled: !_loading,
            onPressed: _submitPhone,
          ),
        ],
      ),
    );
  }

  Widget _sendingStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListenableBuilder(
          listenable: GridTheme.I,
          builder: (_, __) {
            return Icon(Icons.sms_outlined, size: 36, color: Px.accent);
          },
        ),
        const SizedBox(height: 14),
        Text(
          'Enviando a tu celular',
          textAlign: TextAlign.center,
          style: Px.title(9),
        ),
        const SizedBox(height: 8),
        Text(
          _phonePretty,
          textAlign: TextAlign.center,
          style: Px.body.copyWith(color: Px.accent),
        ),
        const SizedBox(height: 8),
        Text(
          'Un código de verificación por SMS…',
          textAlign: TextAlign.center,
          style: Px.label(6, Px.textDim),
        ),
        const SizedBox(height: 18),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 3),
        ),
      ],
    );
  }

  Widget _codeStep() {
    return Form(
      key: _codeKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Verificación',
            textAlign: TextAlign.center,
            style: Px.title(10),
          ),
          const SizedBox(height: 6),
          Text(
            'Código SMS enviado a',
            textAlign: TextAlign.center,
            style: Px.label(6, Px.textDim),
          ),
          Text(
            _phonePretty,
            textAlign: TextAlign.center,
            style: Px.label(7, Px.accent),
          ),
          const SizedBox(height: 14),
          _BitField(
            controller: _codeController,
            hint: 'CÓDIGO',
            keyboardType: TextInputType.number,
            onFieldSubmitted: (_) => _submitCode(),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.length != 6) return '6 dígitos';
              return null;
            },
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          const SizedBox(height: 14),
          PixelButton(
            label: _loading ? '...' : 'VERIFICAR',
            glyph: PixelGlyphKind.check,
            enabled: !_loading,
            onPressed: _submitCode,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loading
                ? null
                : () => _goStep(_AuthStep.phone),
            child: Text('Cambiar número', style: Px.label(6, Px.textDim)),
          ),
        ],
      ),
    );
  }

  Widget _profileStep() {
    final photo = _draftPhoto != null ? localFileProvider(_draftPhoto!) : null;
    return Form(
      key: _profileKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Tu perfil',
            textAlign: TextAlign.center,
            style: Px.title(10),
          ),
          const SizedBox(height: 4),
          Text(
            'Foto real o avatar pixel',
            textAlign: TextAlign.center,
            style: Px.label(6, Px.textDim),
          ),
          const SizedBox(height: 14),
          Center(
            child: AvatarBadge(
              config: _draftAvatar,
              size: 96,
              animate: photo == null,
              photo: photo,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'FOTO',
                  small: true,
                  glyph: PixelGlyphKind.gallery,
                  color: photo != null ? Px.accent : Px.panelLight,
                  textColor: photo != null ? Px.bg : Px.text,
                  onPressed: () => _pickPhoto(ImageSource.gallery),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PixelButton(
                  label: 'CAM',
                  small: true,
                  glyph: PixelGlyphKind.camera,
                  color: Px.panelLight,
                  textColor: Px.text,
                  onPressed: () => _pickPhoto(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PixelButton(
                  label: 'BIT',
                  small: true,
                  glyph: PixelGlyphKind.face,
                  color: photo == null ? Px.accent : Px.panelLight,
                  textColor: photo == null ? Px.bg : Px.text,
                  onPressed: _useAvatarOnly,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: PixelButton(
                  label: 'EDITAR',
                  small: true,
                  glyph: PixelGlyphKind.edit,
                  color: Px.panelLight,
                  textColor: Px.text,
                  onPressed: _editAvatar,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PixelButton(
                  label: 'AZAR',
                  small: true,
                  onPressed: _randomizeAvatar,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: PixelButton(
                  label: 'PIEL',
                  small: true,
                  onPressed: _cycleSkin,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BitField(
            controller: _nameController,
            hint: 'TU NOMBRE',
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => _game.walkWithName(),
            onFieldSubmitted: (_) => _submitProfile(),
            validator: (v) {
              final t = (v ?? '').trim();
              if (t.length < 2) return 'Escribe tu nombre';
              return null;
            },
            inputFormatters: [LengthLimitingTextInputFormatter(24)],
          ),
          const SizedBox(height: 16),
          PixelButton(
            label: _loading ? 'ENTRANDO...' : 'ENTRAR',
            glyph: PixelGlyphKind.check,
            enabled: !_loading,
            onPressed: _submitProfile,
          ),
        ],
      ),
    );
  }
}

/// Panel de login (pixel limpio, sin RGB).
class _BitChip extends StatelessWidget {
  const _BitChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Px.bg,
        border: Border.all(color: Px.border, width: 2),
      ),
      child: Text(label, style: Px.body.copyWith(color: Px.accent)),
    );
  }
}

class _BitField extends StatelessWidget {
  const _BitField({
    required this.controller,
    required this.hint,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Px.border, width: 2),
    );
    final focus = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Px.accent, width: 2),
    );
    final err = OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Px.danger, width: 2),
    );
    return TextFormField(
      controller: controller,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      cursorColor: Px.accent,
      style: Px.body,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: Px.bg,
        hintText: hint,
        hintStyle: Px.label(8, Px.textDim),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        enabledBorder: border,
        focusedBorder: focus,
        errorBorder: err,
        focusedErrorBorder: err,
        errorStyle: Px.label(6, Px.danger),
      ),
    );
  }
}
