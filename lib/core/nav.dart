import 'package:flutter/material.dart';

import '../screens/user_profile_screen.dart';

/// Observador de rutas: permite pausar videos cuando otra pantalla
/// se abre encima (perfil, chat, llamada…).
final routeObserver = RouteObserver<ModalRoute<void>>();

/// Abre el perfil de un usuario (conectado desde feed, chat, amigos, etc.).
void openUserProfile(BuildContext context, String username) {
  final key = username.trim();
  if (key.isEmpty) return;
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => UserProfileScreen(username: key)),
  );
}
