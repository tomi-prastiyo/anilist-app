class ApiConstants {
  ApiConstants._();

  static const String anilistGraphqlUrl = 'https://graphql.anilist.co';
  static const int anilistClientId = 1988;
  static const String anilistWebsiteUrl = 'https://anilist.co';
  static const String anilistAuthUrl =
      '$anilistWebsiteUrl/api/v2/oauth/authorize?client_id=$anilistClientId&response_type=token';
  static const String anilistSignupUrl = '$anilistWebsiteUrl/signup';
  static const String anilistDeveloperUrl = '$anilistWebsiteUrl/settings/developer';

  // API rate limit values
  static const int maxRequestsPerMinute = 85; // Safe threshold under 90
  static const Duration requestTimeout = Duration(seconds: 20);
}
