import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'config/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const double size = 1024;

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  // White background
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, size, size),
    Paint()..color = Colors.white,
  );

  // Draw the blue sports icon
  final painter = TextPainter(
    text: TextSpan(
      text: String.fromCharCode(Icons.sports_rounded.codePoint),
      style: TextStyle(
        fontSize: 650,
        fontFamily: Icons.sports_rounded.fontFamily,
        package: Icons.sports_rounded.fontPackage,
        color: AppColors.primary,
      ),
    ),
    textDirection: TextDirection.ltr,
  );

  painter.layout();

  painter.paint(
    canvas,
    Offset((size - painter.width) / 2, (size - painter.height) / 2),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(1024, 1024);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  final directory = Directory('assets/icon');
  await directory.create(recursive: true);

  final file = File('assets/icon/app_icon.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());

  print('Icon created: ${file.path}');
}
