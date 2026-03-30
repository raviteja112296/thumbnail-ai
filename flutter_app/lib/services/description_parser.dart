import 'package:flutter/material.dart';
import '../models/thumbnail_data.dart';

class DescriptionParser {

  static Color _parseHexColor(String hex, Color fallback) {
    try {
      hex = hex.replaceAll('#', '').trim();
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  static List<String> _extractHexColors(String text) {
    final regex = RegExp(r'#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})\b');
    return regex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  static String _extractTitle(String description) {
    // Try to find bold title patterns like **Title: "something"**
    final boldTitle = RegExp(r'\*\*Title[:\s]*["""]?([^*"""\n]+)["""]?\*\*');
    final m1 = boldTitle.firstMatch(description);
    if (m1 != null) return m1.group(1)!.trim();

    // Try quoted title
    final quoted = RegExp(r'["""]([^"""]{10,60})["""]');
    final m2 = quoted.firstMatch(description);
    if (m2 != null) return m2.group(1)!.trim();

    // Fallback: grab text after "Title:" or "title:"
    final titleLine = RegExp(r'[Tt]itle[:\s]+(.+)');
    final m3 = titleLine.firstMatch(description);
    if (m3 != null) {
      final raw = m3.group(1)!.replaceAll(RegExp(r'\*+'), '').trim();
      if (raw.length < 80) return raw;
    }

    return 'YouTube Thumbnail';
  }

  static String _extractSubtitle(String description) {
    final sub = RegExp(r'[Ss]ubtitle[:\s]+(.+)');
    final m = sub.firstMatch(description);
    if (m != null) {
      return m.group(1)!.replaceAll(RegExp(r'\*+'), '').trim();
    }
    return '';
  }

  static ThumbnailData parse(String description) {
    final colors = _extractHexColors(description);

    // Background colors
    final bg1 = colors.isNotEmpty
        ? _parseHexColor(colors[0], const Color(0xFF1A237E))
        : const Color(0xFF1A237E);

    final bg2 = colors.length > 1
        ? _parseHexColor(colors[1], const Color(0xFF0D47A1))
        : const Color(0xFF0D47A1);

    // Text colors
    final titleColor = colors.length > 2
        ? _parseHexColor(colors[2], Colors.white)
        : Colors.white;

    final subtitleColor = colors.length > 3
        ? _parseHexColor(colors[3], const Color(0xFFB3E5FC))
        : const Color(0xFFB3E5FC);

    // Extract mood keywords for layout decisions
    final descLower = description.toLowerCase();
    String mood = 'professional';
    if (descLower.contains('dramatic')) mood = 'dramatic';
    if (descLower.contains('fun') || descLower.contains('playful')) mood = 'fun';
    if (descLower.contains('dark') || descLower.contains('mystery')) mood = 'dark';
    if (descLower.contains('minimal')) mood = 'minimal';

    // Extract graphic elements mentioned
    final elements = <String>[];
    if (descLower.contains('java')) elements.add('java');
    if (descLower.contains('python')) elements.add('python');
    if (descLower.contains('fire')) elements.add('fire');
    if (descLower.contains('arrow')) elements.add('arrow');
    if (descLower.contains('star')) elements.add('star');
    if (descLower.contains('lightning')) elements.add('lightning');
    if (descLower.contains('code') || descLower.contains('bracket')) {
      elements.add('code');
    }

    return ThumbnailData(
      backgroundColor1: bg1,
      backgroundColor2: bg2,
      title: _extractTitle(description),
      subtitle: _extractSubtitle(description),
      titleColor: titleColor,
      subtitleColor: subtitleColor,
      mood: mood,
      elements: elements,
    );
  }
}