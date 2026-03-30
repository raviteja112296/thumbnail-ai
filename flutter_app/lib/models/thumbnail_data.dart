import 'package:flutter/material.dart';

class ThumbnailData {
  final Color backgroundColor1;
  final Color backgroundColor2;
  final String title;
  final String subtitle;
  final Color titleColor;
  final Color subtitleColor;
  final String mood;
  final List<String> elements;

  ThumbnailData({
    required this.backgroundColor1,
    required this.backgroundColor2,
    required this.title,
    required this.subtitle,
    required this.titleColor,
    required this.subtitleColor,
    required this.mood,
    required this.elements,
  });
}