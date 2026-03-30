import 'package:flutter/material.dart';
import '../models/thumbnail_data.dart';

class ThumbnailPainter extends CustomPainter {
  final ThumbnailData data;

  ThumbnailPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1 — Background gradient
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [data.backgroundColor1, data.backgroundColor2],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2 — Subtle grid overlay
    _drawGrid(canvas, w, h);

    // 3 — Accent bar on left
    final accentPaint = Paint()
      ..color = data.titleColor.withOpacity(0.8)
      ..strokeWidth = 8;
    canvas.drawLine(Offset(40, h * 0.2), Offset(40, h * 0.8), accentPaint);

    // 4 — Decorative circle (top right)
    final circlePaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.85, h * 0.2), h * 0.5, circlePaint);
    canvas.drawCircle(Offset(w * 0.85, h * 0.2), h * 0.35, Paint()
      ..color = Colors.white.withOpacity(0.05));

    // 5 — Draw elements/icons (text-based)
    if (data.elements.contains('code') || data.elements.contains('java')) {
      _drawCodeDecor(canvas, w, h);
    }

    // 6 — Title text
    _drawTitle(canvas, w, h);

    // 7 — Subtitle text
    if (data.subtitle.isNotEmpty) {
      _drawSubtitle(canvas, w, h);
    }

    // 8 — Bottom brand strip
    _drawBottomStrip(canvas, w, h);
  }

  void _drawGrid(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 1;
    for (double x = 0; x < w; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), paint);
    }
    for (double y = 0; y < h; y += 60) {
      canvas.drawLine(Offset(0, y), Offset(w, y), paint);
    }
  }

  void _drawCodeDecor(Canvas canvas, double w, double h) {
    final style = TextStyle(
      color: Colors.white.withOpacity(0.08),
      fontSize: 28,
      fontFamily: 'monospace',
      fontWeight: FontWeight.bold,
    );
    final snippets = ['{ }', '</>', '( )', '[];', '=>'];
    final positions = [
      Offset(w * 0.72, h * 0.08),
      Offset(w * 0.82, h * 0.65),
      Offset(w * 0.60, h * 0.75),
      Offset(w * 0.90, h * 0.40),
      Offset(w * 0.65, h * 0.15),
    ];
    for (int i = 0; i < snippets.length; i++) {
      _drawText(canvas, snippets[i], positions[i], style,
          maxWidth: 120, align: TextAlign.left);
    }
  }

  void _drawTitle(Canvas canvas, double w, double h) {
    final title = data.title;
    final fontSize = title.length > 40 ? 52.0 : title.length > 25 ? 62.0 : 72.0;

    final style = TextStyle(
      color: data.titleColor,
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: -1,
      shadows: [
        Shadow(
          color: Colors.black.withOpacity(0.5),
          offset: const Offset(3, 3),
          blurRadius: 8,
        )
      ],
    );

    _drawText(
      canvas, title,
      Offset(70, h * 0.28),
      style,
      maxWidth: w * 0.85,
      align: TextAlign.left,
    );
  }

  void _drawSubtitle(Canvas canvas, double w, double h) {
    final style = TextStyle(
      color: data.subtitleColor,
      fontSize: 36,
      fontWeight: FontWeight.w500,
      letterSpacing: 1,
    );
    _drawText(
      canvas, data.subtitle,
      Offset(70, h * 0.68),
      style,
      maxWidth: w * 0.75,
      align: TextAlign.left,
    );
  }

  void _drawBottomStrip(Canvas canvas, double w, double h) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.25);
    canvas.drawRect(Rect.fromLTWH(0, h * 0.88, w, h * 0.12), paint);

    final style = TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: 22,
      fontWeight: FontWeight.w400,
      letterSpacing: 2,
    );
    _drawText(canvas, 'THUMBNAIL AI  •  GENERATED',
      Offset(70, h * 0.915), style,
      maxWidth: w * 0.8, align: TextAlign.left);
  }

  void _drawText(Canvas canvas, String text, Offset position,
      TextStyle style, {required double maxWidth,
      TextAlign align = TextAlign.left}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: maxWidth);
    tp.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}