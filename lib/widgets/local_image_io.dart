import 'dart:io';

import 'package:flutter/widgets.dart';

/// Imagen desde ruta local (Windows / móvil).
Widget? localFileImage(String path) {
  return Image.file(
    File(path),
    fit: BoxFit.cover,
    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
  );
}

ImageProvider? localFileProvider(String path) => FileImage(File(path));
