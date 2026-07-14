import 'package:flutter/material.dart';

class ListBackground {
  const ListBackground({
    required this.key,
    required this.name,
    required this.nameTr,
    required this.gradient,
  });

  final String key;
  final String name;
  final String nameTr;
  final LinearGradient gradient;

  static const List<ListBackground> presets = [
    ListBackground(
      key: 'ocean',
      name: 'Ocean',
      nameTr: 'Okyanus',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1565C0), Color(0xFF00838F)],
      ),
    ),
    ListBackground(
      key: 'forest',
      name: 'Forest',
      nameTr: 'Orman',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B5E20), Color(0xFF558B2F)],
      ),
    ),
    ListBackground(
      key: 'sunset',
      name: 'Sunset',
      nameTr: 'Gün Batımı',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF57F17), Color(0xFFAD1457), Color(0xFF4A148C)],
      ),
    ),
    ListBackground(
      key: 'midnight',
      name: 'Midnight',
      nameTr: 'Gece Yarısı',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D0D2B), Color(0xFF1A237E)],
      ),
    ),
    ListBackground(
      key: 'rose',
      name: 'Rose',
      nameTr: 'Gül',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFE91E63), Color(0xFFB71C1C)],
      ),
    ),
    ListBackground(
      key: 'citrus',
      name: 'Citrus',
      nameTr: 'Narenciye',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF9A825), Color(0xFFE64A19)],
      ),
    ),
    ListBackground(
      key: 'lavender',
      name: 'Lavender',
      nameTr: 'Lavanta',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF7E57C2), Color(0xFF42A5F5)],
      ),
    ),
    ListBackground(
      key: 'ember',
      name: 'Ember',
      nameTr: 'Kor',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF3E0000), Color(0xFFBF360C)],
      ),
    ),
    ListBackground(
      key: 'arctic',
      name: 'Arctic',
      nameTr: 'Arktik',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF80DEEA), Color(0xFFE0F7FA)],
      ),
    ),
    ListBackground(
      key: 'jungle',
      name: 'Jungle',
      nameTr: 'Orman İçi',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF004D40), Color(0xFF00897B)],
      ),
    ),
    ListBackground(
      key: 'berry',
      name: 'Berry',
      nameTr: 'Yemiş',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF4A148C), Color(0xFFAD1457)],
      ),
    ),
    ListBackground(
      key: 'mist',
      name: 'Mist',
      nameTr: 'Sis',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF546E7A), Color(0xFF90A4AE)],
      ),
    ),
  ];

  static LinearGradient? gradientForKey(String? key) {
    if (key == null) return null;
    for (final preset in presets) {
      if (preset.key == key) return preset.gradient;
    }
    return null;
  }

  static String localizedName(ListBackground bg, String locale) {
    return locale == 'tr' ? bg.nameTr : bg.name;
  }
}
