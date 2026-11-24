import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final int id;
  final String name;
  final String? about;
  final String? avatarUrl;
  final String? bannerUrl;
  final String titleLanguage;
  final String scoreFormat;
  final String? profileColor;
  final bool displayAdultContent;
  final int unreadNotificationCount;

  const UserModel({
    required this.id,
    required this.name,
    this.about,
    this.avatarUrl,
    this.bannerUrl,
    this.titleLanguage = 'ROMAJI',
    this.scoreFormat = 'POINT_100',
    this.profileColor,
    this.displayAdultContent = false,
    this.unreadNotificationCount = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map<String, dynamic>?;
    final mediaListOptions = json['mediaListOptions'] as Map<String, dynamic>?;
    final avatar = json['avatar'] as Map<String, dynamic>?;

    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'User',
      about: json['about'] as String?,
      avatarUrl: avatar?['large'] ?? avatar?['medium'],
      bannerUrl: json['bannerImage'] as String?,
      titleLanguage: options?['titleLanguage'] as String? ?? 'ROMAJI',
      scoreFormat: mediaListOptions?['scoreFormat'] as String? ?? 'POINT_100',
      profileColor: options?['profileColor'] as String?,
      displayAdultContent: options?['displayAdultContent'] as bool? ?? false,
      unreadNotificationCount: json['unreadNotificationCount'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        about,
        avatarUrl,
        bannerUrl,
        titleLanguage,
        scoreFormat,
        profileColor,
        displayAdultContent,
        unreadNotificationCount,
      ];
}
