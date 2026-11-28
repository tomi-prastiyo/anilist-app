import 'package:flutter/material.dart';

/// Official verified AniList CDN assets & Hero franchise palettes for
/// *Yuuki Yuuna wa Yuusha de Aru* across all major chapters (`YuYuYu`, `WaSuYu`,
/// `NoWaYu`, `KuMeYu`, `YuYuYui`).
class YuYuYuHeroine {
  final String id;
  final int characterId;
  final String name;
  final String shortName;
  final String chapterGroup;
  final String chapterLabel;
  final String roleTitle;
  final String flowerMotif;
  final String fairyName;
  final String clubTenet;
  final String cuteGreeting;
  final String chibiAsset;
  final String fairyAsset;
  final String imageUrl;
  final Color accentColor;

  const YuYuYuHeroine({
    required this.id,
    required this.characterId,
    required this.name,
    required this.shortName,
    required this.chapterGroup,
    required this.chapterLabel,
    required this.roleTitle,
    required this.flowerMotif,
    required this.fairyName,
    required this.clubTenet,
    required this.cuteGreeting,
    required this.chibiAsset,
    required this.fairyAsset,
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
  static const Color shinjuGoldSoft = Color(0xFFFDE68A);
  static const Color jukaiGlow = Color(0xFF3E1F5B);
  static const Color twilightBg = Color(0xFF120B1C);
  static const Color twilightSurface = Color(0xFF1C122B);
  static const Color twilightCard = Color(0xFF241738);
  static const Color twilightInput = Color(0xFF0E0816);
  static const Color twilightBorder = Color(0xFF3A2554);
  static const Color blossomTextPrimary = Color(0xFFFDF6FA);
  static const Color blossomTextSecondary = Color(0xFFCBB8D9);
  static const Color blossomTextMuted = Color(0xFF937CA8);

  static const List<String> chapterFilters = [
    'All',
    'YuYuYu',
    'WaSuYu',
    'NoWaYu',
    'KuMeYu',
    'YuYuYui',
  ];

  static List<YuYuYuHeroine> byChapter(String chapter) {
    if (chapter == 'All') return heroines;
    return heroines.where((h) => h.chapterGroup == chapter).toList();
  }

  static const List<YuYuYuHeroine> heroines = [
    // --- Sanshu Hero Club (YuYuYu) ---
    YuYuYuHeroine(
      id: 'yuuna',
      characterId: 88636,
      name: 'Yuuna Yuuki',
      shortName: 'Yuuna',
      chapterGroup: 'YuYuYu',
      chapterLabel: 'Sanshu Hero Club',
      roleTitle: 'Mankai Sakura',
      flowerMotif: 'Sakura',
      fairyName: 'Gyuki',
      clubTenet: '“You’re likely to succeed if you try!”',
      cuteGreeting: 'Mankai! Ganbarou~ 🌸',
      chibiAsset: 'assets/images/yuyuyu/chibi_yuuna.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_gyuuki.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88636-qlblbpue9jvK.jpg',
      accentColor: Color(0xFFF472B6),
    ),
    YuYuYuHeroine(
      id: 'mimori',
      characterId: 88637,
      name: 'Mimori Tougou',
      shortName: 'Mimori',
      chapterGroup: 'YuYuYu',
      chapterLabel: 'Sanshu Hero Club',
      roleTitle: 'Royal Indigo',
      flowerMotif: 'Morning Glory',
      fairyName: 'Aobozu',
      clubTenet: '“If you’re troubled, consult someone!”',
      cuteGreeting: 'Otsukaresama desu~ ♪',
      chibiAsset: 'assets/images/yuyuyu/chibi_mimori.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_aobozu.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88637-WXqWFtEUnSt6.jpg',
      accentColor: Color(0xFF60A5FA),
    ),
    YuYuYuHeroine(
      id: 'fuu',
      characterId: 88638,
      name: 'Fuu Inubouzaki',
      shortName: 'Fuu',
      chapterGroup: 'YuYuYu',
      chapterLabel: 'Sanshu Hero Club',
      roleTitle: 'Shinju Gold',
      flowerMotif: 'Yellow Hibiscus',
      fairyName: 'Inugami',
      clubTenet: '“Greet others properly!”',
      cuteGreeting: 'Hero Club, roll out! ✨',
      chibiAsset: 'assets/images/yuyuyu/chibi_fuu.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_inugami.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88638-0I3nqQKI774u.png',
      accentColor: Color(0xFFFBBF24),
    ),
    YuYuYuHeroine(
      id: 'itsuki',
      characterId: 88639,
      name: 'Itsuki Inubouzaki',
      shortName: 'Itsuki',
      chapterGroup: 'YuYuYu',
      chapterLabel: 'Sanshu Hero Club',
      roleTitle: 'Emerald Leaf',
      flowerMotif: 'Green Bellflower',
      fairyName: 'Kodama',
      clubTenet: '“Sleep well, eat well!”',
      cuteGreeting: 'Tarot says today is lucky~ 🍀',
      chibiAsset: 'assets/images/yuyuyu/chibi_itsuki.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_kodama.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88639-mGNBV2FXxR8V.jpg',
      accentColor: Color(0xFF4CC38A),
    ),
    YuYuYuHeroine(
      id: 'karin',
      characterId: 88640,
      name: 'Karin Miyoshi',
      shortName: 'Karin',
      chapterGroup: 'YuYuYu',
      chapterLabel: 'Sanshu Hero Club',
      roleTitle: 'Crimson Flame',
      flowerMotif: 'Red Hibiscus',
      fairyName: 'Yoshiteru',
      clubTenet: '“Try not to give up!”',
      cuteGreeting: 'Hmph! Keep up the pace! 🔥',
      chibiAsset: 'assets/images/yuyuyu/chibi_karin.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_yoshiteru.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88640-Zpb2n4Kft1GD.jpg',
      accentColor: Color(0xFFFB7185),
    ),
    YuYuYuHeroine(
      id: 'sonoko',
      characterId: 88641,
      name: 'Sonoko Nogi',
      shortName: 'Sonoko',
      chapterGroup: 'YuYuYu',
      chapterLabel: 'Sanshu Hero Club',
      roleTitle: 'Soft Blossom',
      flowerMotif: 'Mankai Blossom',
      fairyName: '21 Fairies',
      clubTenet: '“Even in full bloom, we walk together!”',
      cuteGreeting: 'Wasshi & Nogi-chan desu~ 🌷',
      chibiAsset: 'assets/images/yuyuyu/chibi_sonoko.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_kasha.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88641-ikpD1qwAjhmF.png',
      accentColor: Color(0xFFF9A8D4),
    ),

    // --- Washio Sumi Chapter (WaSuYu) ---
    YuYuYuHeroine(
      id: 'sumi',
      characterId: 88637,
      name: 'Sumi Washio',
      shortName: 'Sumi',
      chapterGroup: 'WaSuYu',
      chapterLabel: 'Washio Sumi Chapter',
      roleTitle: 'Shinju Sniper',
      flowerMotif: 'Japanese Iris',
      fairyName: 'Aobozu',
      clubTenet: '“Stand tall and uphold your duty as a Hero.”',
      cuteGreeting: 'Sumi Washio, ready to defend! 🏹',
      chibiAsset: 'assets/images/yuyuyu/chibi_sumi.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_aobozu.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b88637-WXqWFtEUnSt6.jpg',
      accentColor: Color(0xFF38BDF8),
    ),
    YuYuYuHeroine(
      id: 'gin',
      characterId: 124148,
      name: 'Gin Minowa',
      shortName: 'Gin',
      chapterGroup: 'WaSuYu',
      chapterLabel: 'Washio Sumi Chapter',
      roleTitle: 'Twin Blades',
      flowerMotif: 'Red Rose',
      fairyName: 'Yoshiteru',
      clubTenet: '“Protect the ones you love with everything!”',
      cuteGreeting: 'Wasshi, Sonocchi, let’s go! 🌹',
      chibiAsset: 'assets/images/yuyuyu/chibi_gin.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_yoshiteru.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b124148-H8l9zsZ5NuzF.png',
      accentColor: Color(0xFFEF4444),
    ),

    // --- Nogi Wakaba is a Hero (NoWaYu) ---
    YuYuYuHeroine(
      id: 'wakaba',
      characterId: 126200,
      name: 'Wakaba Nogi',
      shortName: 'Wakaba',
      chapterGroup: 'NoWaYu',
      chapterLabel: 'Nogi Wakaba is a Hero',
      roleTitle: 'First Hero Leader',
      flowerMotif: 'Wisteria',
      fairyName: 'Yoshiteru',
      clubTenet: '“Lead forward, no matter how fierce the storm.”',
      cuteGreeting: 'Nogi Wakaba, cutting through! ⚔️',
      chibiAsset: 'assets/images/yuyuyu/chibi_wakaba.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_yoshiteru.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b126200-x3zUygRnG68A.jpg',
      accentColor: Color(0xFF818CF8),
    ),
    YuYuYuHeroine(
      id: 'hinata',
      characterId: 126245,
      name: 'Hinata Uesato',
      shortName: 'Hinata',
      chapterGroup: 'NoWaYu',
      chapterLabel: 'Nogi Wakaba is a Hero',
      roleTitle: 'Shrine Maiden',
      flowerMotif: 'Hydrangea',
      fairyName: 'Kodama',
      clubTenet: '“Stand beside Wakaba-chan through every trial.”',
      cuteGreeting: 'May Shinju-sama guide us~ ✨',
      chibiAsset: 'assets/images/yuyuyu/chibi_hinata.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_kodama.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b126245-B3cm11ZSyXlN.jpg',
      accentColor: Color(0xFFF59E0B),
    ),
    YuYuYuHeroine(
      id: 'takashima',
      characterId: 126201,
      name: 'Yuuna Takashima',
      shortName: 'Takashima',
      chapterGroup: 'NoWaYu',
      chapterLabel: 'Nogi Wakaba is a Hero',
      roleTitle: 'Pioneer Striker',
      flowerMotif: 'Yamazakura',
      fairyName: 'Gyuki',
      clubTenet: '“A Hero fights with a bright smile!”',
      cuteGreeting: 'Yuuna Takashima, coming right up! 🌸',
      chibiAsset: 'assets/images/yuyuyu/chibi_takashima.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_gyuuki.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b126201-1f5V7s3fLQVS.jpg',
      accentColor: Color(0xFFF472B6),
    ),
    YuYuYuHeroine(
      id: 'chikage',
      characterId: 126240,
      name: 'Chikage Koori',
      shortName: 'Chikage',
      chapterGroup: 'NoWaYu',
      chapterLabel: 'Nogi Wakaba is a Hero',
      roleTitle: 'Scythe Striker',
      flowerMotif: 'Spider Lily',
      fairyName: 'Aobozu',
      clubTenet: '“Even in darkness, prove your worth.”',
      cuteGreeting: 'Don’t get in my way... 💜',
      chibiAsset: 'assets/images/yuyuyu/chibi_chikage.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_aobozu.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b126240-wKYYgKIEOgR2.png',
      accentColor: Color(0xFFA855F7),
    ),
    YuYuYuHeroine(
      id: 'tamako',
      characterId: 126241,
      name: 'Tamako Doi',
      shortName: 'Tamako',
      chapterGroup: 'NoWaYu',
      chapterLabel: 'Nogi Wakaba is a Hero',
      roleTitle: 'Iron Chain',
      flowerMotif: 'Sunflower',
      fairyName: 'Inugami',
      clubTenet: '“Protect Anzu and everyone like a big sister!”',
      cuteGreeting: 'Leave the vanguard to me! 🌻',
      chibiAsset: 'assets/images/yuyuyu/chibi_tamako.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_inugami.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b126241-9ertEn2nIwGf.jpg',
      accentColor: Color(0xFFFB923C),
    ),
    YuYuYuHeroine(
      id: 'anzu',
      characterId: 126244,
      name: 'Anzu Iyojima',
      shortName: 'Anzu',
      chapterGroup: 'NoWaYu',
      chapterLabel: 'Nogi Wakaba is a Hero',
      roleTitle: 'Tactical Crossbow',
      flowerMotif: 'Clover',
      fairyName: 'Kodama',
      clubTenet: '“Every quiet page can save a life.”',
      cuteGreeting: 'Tama-chan and I are supporting you~ 🍀',
      chibiAsset: 'assets/images/yuyuyu/chibi_anzu.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_kodama.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b126244-X6RnWOGJnWIz.jpg',
      accentColor: Color(0xFF34D399),
    ),

    // --- Kusunoki Mebuki is a Hero (KuMeYu) ---
    YuYuYuHeroine(
      id: 'mebuki',
      characterId: 136191,
      name: 'Mebuki Kusunoki',
      shortName: 'Mebuki',
      chapterGroup: 'KuMeYu',
      chapterLabel: 'Kusunoki Mebuki is a Hero',
      roleTitle: 'Sentinel Captain',
      flowerMotif: 'Camphor Leaf',
      fairyName: 'Yoshiteru',
      clubTenet: '“Sentinels bring every squadmate back alive!”',
      cuteGreeting: 'Sentinel squad, move out! 🌿',
      chibiAsset: 'assets/images/yuyuyu/chibi_mebuki.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_yoshiteru.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b136191-S4fUcahZXsta.jpg',
      accentColor: Color(0xFF10B981),
    ),
    YuYuYuHeroine(
      id: 'suzume',
      characterId: 136190,
      name: 'Suzume Kagajou',
      shortName: 'Suzume',
      chapterGroup: 'KuMeYu',
      chapterLabel: 'Kusunoki Mebuki is a Hero',
      roleTitle: 'Tower Shield',
      flowerMotif: 'Marigold',
      fairyName: 'Inugami',
      clubTenet: '“Hold the line, even with shaking knees!”',
      cuteGreeting: 'Eek! I’ll guard you, Mebuki-san! 🛡️',
      chibiAsset: 'assets/images/yuyuyu/chibi_suzume.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_inugami.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b136190-WOBD3WHe2HTW.png',
      accentColor: Color(0xFFFBBF24),
    ),
    YuYuYuHeroine(
      id: 'aya',
      characterId: 136192,
      name: 'Aya Kokudo',
      shortName: 'Aya',
      chapterGroup: 'KuMeYu',
      chapterLabel: 'Kusunoki Mebuki is a Hero',
      roleTitle: 'Sentinel Miko',
      flowerMotif: 'Peach Blossom',
      fairyName: 'Kasha',
      clubTenet: '“Kindness reaches even beyond the barrier.”',
      cuteGreeting: 'Otsukare, everyone~ Have some tea! 🍑',
      chibiAsset: 'assets/images/yuyuyu/chibi_aya.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_kasha.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b136192-R2NCDxDdId4G.png',
      accentColor: Color(0xFFFDA4AF),
    ),
    YuYuYuHeroine(
      id: 'shizuku',
      characterId: 136193,
      name: 'Shizuku Yamabushi',
      shortName: 'Shizuku',
      chapterGroup: 'KuMeYu',
      chapterLabel: 'Kusunoki Mebuki is a Hero',
      roleTitle: 'Wild Hunter',
      flowerMotif: 'Kerria Rose',
      fairyName: 'Gyuki',
      clubTenet: '“Trust your instincts when survival calls.”',
      cuteGreeting: 'Target locked. Ready when you are. 🔥',
      chibiAsset: 'assets/images/yuyuyu/chibi_shizuku.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_gyuuki.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b136193-mzaykdbCfiby.png',
      accentColor: Color(0xFFE11D48),
    ),
    YuYuYuHeroine(
      id: 'yumiko',
      characterId: 136194,
      name: 'Yumiko Miroku',
      shortName: 'Yumiko',
      chapterGroup: 'KuMeYu',
      chapterLabel: 'Kusunoki Mebuki is a Hero',
      roleTitle: 'Noble Blade',
      flowerMotif: 'Peony',
      fairyName: 'Kasha',
      clubTenet: '“A true Sentinel acts with grace and pride.”',
      cuteGreeting: 'Ohoho! Leave this to Lady Miroku! ⚜️',
      chibiAsset: 'assets/images/yuyuyu/chibi_yumiko.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_kasha.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b136194-eWhrl0oqVLVT.png',
      accentColor: Color(0xFFC084FC),
    ),

    // --- Hanayui no Kirameki / Shiratori (YuYuYui) ---
    YuYuYuHeroine(
      id: 'utano',
      characterId: 136164,
      name: 'Utano Shiratori',
      shortName: 'Utano',
      chapterGroup: 'YuYuYui',
      chapterLabel: 'Hanayui no Kirameki',
      roleTitle: 'Suwa Hero',
      flowerMotif: 'Rapeseed',
      fairyName: 'Inugami',
      clubTenet: '“Cultivate the fields and defend our home!”',
      cuteGreeting: 'Fresh veggies and Hero spirit~ 🌾',
      chibiAsset: 'assets/images/yuyuyu/chibi_utano.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_inugami.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b136164-QjfpcRNfnfSQ.png',
      accentColor: Color(0xFFA3E635),
    ),
    YuYuYuHeroine(
      id: 'mito',
      characterId: 136195,
      name: 'Mito Fujimori',
      shortName: 'Mito',
      chapterGroup: 'YuYuYui',
      chapterLabel: 'Hanayui no Kirameki',
      roleTitle: 'Suwa Support',
      flowerMotif: 'Water Lily',
      fairyName: 'Aobozu',
      clubTenet: '“Steady support keeps the whole team blooming.”',
      cuteGreeting: 'Utano-chan and I are cheering for you! 💧',
      chibiAsset: 'assets/images/yuyuyu/chibi_mito.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_aobozu.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b136195-zkjsWBTLCD5e.png',
      accentColor: Color(0xFF22D3EE),
    ),
    YuYuYuHeroine(
      id: 'akamine',
      characterId: 209391,
      name: 'Yuuna Akamine',
      shortName: 'Akamine',
      chapterGroup: 'YuYuYui',
      chapterLabel: 'Hanayui no Kirameki',
      roleTitle: 'Bofuu Hero',
      flowerMotif: 'Red Sakura',
      fairyName: 'Gyuki',
      clubTenet: '“Eat plenty of curry udon and keep moving!”',
      cuteGreeting: 'Yuuna Akamine! Ready for dessert~ 🍛',
      chibiAsset: 'assets/images/yuyuyu/chibi_akamine.png',
      fairyAsset: 'assets/images/yuyuyu/fairy_gyuuki.png',
      imageUrl: 'https://s4.anilist.co/file/anilistcdn/character/large/b209391-RYTVk7l8J7uw.png',
      accentColor: Color(0xFFFB7185),
    ),
  ];

  static YuYuYuHeroine byId(String? id) {
    if (id == null) return heroines.first;
    return heroines.firstWhere((h) => h.id == id, orElse: () => heroines.first);
  }
}
