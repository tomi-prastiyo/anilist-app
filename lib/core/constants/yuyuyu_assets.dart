import 'package:flutter/material.dart';

/// Official verified AniList CDN assets & Hero Club palette for *Yuuki Yuuna wa Yuusha de Aru*.
class YuYuYuHeroine {
  final String id;
  final int characterId;
  final String name;
  final String roleTitle;
  final String imageUrl;
  final Color accentColor;

  const YuYuYuHeroine({
    required this.id,
    required this.characterId,
    required this.name,
    required this.roleTitle,
    required this.imageUrl,
    required this.accentColor,
  });
}

class YuYuYuAssets {
  YuYuYuAssets._();

  static const int mediaId = 20800;
  static const String animeTitle = 'Yuuki Yuuna wa Yuusha de Aru';
  static const String bannerUrl =
      'https://s4.anilist.co/file/anilistcdn/media/anime/banner/20800-KpoJB6tGnj2V.jpg';
  static const String coverUrl =
      'https://s4.anilist.co/file/anilistcdn/media/anime/cover/large/bx20800-7IAW762FbSFU.png';

  static const Color shinjuGold = Color(0xFFFBBF24);
  static const Color twilightBg = Color(0xFF120B1C);
  static const Color twilightSurface = Color(0xFF1C122B);
  static const Color twilightCard = Color(0xFF241738);
  static const Color twilightInput = Color(0xFF0E0816);
  static const Color twilightBorder = Color(0xFF3A2554);
  static const Color blossomTextPrimary = Color(0xFFFDF6FA);
  static const Color blossomTextSecondary = Color(0xFFCBB8D9);
  static const Color blossomTextMuted = Color(0xFF937CA8);

  static const List<YuYuYuHeroine> heroines = [
    YuYuYuHeroine(
      id: 'yuuna',
      characterId: 88636,
      name: 'Yuuna Yuuki',
      roleTitle: 'Mankai Sakura',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88636-qlblbpue9jvK.jpg',
      accentColor: Color(0xFFF472B6),
    ),
    YuYuYuHeroine(
      id: 'mimori',
      characterId: 88637,
      name: 'Mimori Tougou',
      roleTitle: 'Royal Indigo',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88637-WXqWFtEUnSt6.jpg',
      accentColor: Color(0xFF60A5FA),
    ),
    YuYuYuHeroine(
      id: 'fuu',
      characterId: 88638,
      name: 'Fuu Inubouzaki',
      roleTitle: 'Shinju Gold',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88638-0I3nqQKI774u.png',
      accentColor: Color(0xFFFBBF24),
    ),
    YuYuYuHeroine(
      id: 'itsuki',
      characterId: 88639,
      name: 'Itsuki Inubouzaki',
      roleTitle: 'Emerald Leaf',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88639-mGNBV2FXxR8V.jpg',
      accentColor: Color(0xFF4CC38A),
    ),
    YuYuYuHeroine(
      id: 'karin',
      characterId: 88640,
      name: 'Karin Miyoshi',
      roleTitle: 'Crimson Flame',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88640-Zpb2n4Kft1GD.jpg',
      accentColor: Color(0xFFFB7185),
    ),
    YuYuYuHeroine(
      id: 'sonoko',
      characterId: 88641,
      name: 'Sonoko Nogi',
      roleTitle: 'Soft Blossom',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88641-ikpD1qwAjhmF.png',
      accentColor: Color(0xFFF9A8D4),
    ),
  ];

  static YuYuYuHeroine byId(String? id) {
    if (id == null) return heroines.first;
    return heroines.firstWhere((h) => h.id == id, orElse: () => heroines.first);
  }
}
