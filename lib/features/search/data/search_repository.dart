import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SearchRepository(apiClient);
});

class SearchRepository {
  final ApiClient _apiClient;

  SearchRepository(this._apiClient);

  static const String searchMediaQuery = r'''
    query SearchMediaQuery(
      $page: Int,
      $perPage: Int,
      $search: String,
      $type: MediaType,
      $sort: [MediaSort],
      $genreIn: [String],
      $genreNotIn: [String],
      $formatIn: [MediaFormat],
      $statusIn: [MediaStatus],
      $seasonYear: Int
    ) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          currentPage
          hasNextPage
        }
        media(
          search: $search,
          type: $type,
          sort: $sort,
          genre_in: $genreIn,
          genre_not_in: $genreNotIn,
          format_in: $formatIn,
          status_in: $statusIn,
          seasonYear: $seasonYear,
          isAdult: false
        ) {
          id
          title {
            romaji
            english
            native
            userPreferred
          }
          type
          format
          status
          episodes
          chapters
          averageScore
          coverImage {
            large
            medium
          }
        }
      }
    }
  ''';

  static const String searchCharacterQuery = r'''
    query SearchCharacterQuery($page: Int, $perPage: Int, $search: String) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          currentPage
          hasNextPage
        }
        characters(search: $search) {
          id
          name {
            userPreferred
            full
          }
          image {
            medium
          }
        }
      }
    }
  ''';

  static const String searchStaffQuery = r'''
    query SearchStaffQuery($page: Int, $perPage: Int, $search: String) {
      Page(page: $page, perPage: $perPage) {
        pageInfo {
          currentPage
          hasNextPage
        }
        staff(search: $search) {
          id
          name {
            userPreferred
            full
          }
          image {
            medium
          }
          primaryOccupations
        }
      }
    }
  ''';

  Future<Map<String, dynamic>> searchMedia({
    required int page,
    int perPage = 20,
    String? search,
    required String type, // ANIME or MANGA
    List<String>? genreIn,
    List<String>? genreNotIn,
    List<String>? formatIn,
    List<String>? statusIn,
    int? seasonYear,
    String? sortBy,
  }) async {
    final Map<String, dynamic> vars = {
      'page': page,
      'perPage': perPage,
      'type': type,
      'sort': [sortBy ?? ((search != null && search.isNotEmpty) ? 'SEARCH_MATCH' : 'POPULARITY_DESC')],
    };
    if (search != null && search.isNotEmpty) vars['search'] = search;
    if (genreIn != null && genreIn.isNotEmpty) vars['genreIn'] = genreIn;
    if (genreNotIn != null && genreNotIn.isNotEmpty) vars['genreNotIn'] = genreNotIn;
    if (formatIn != null && formatIn.isNotEmpty) vars['formatIn'] = formatIn;
    if (statusIn != null && statusIn.isNotEmpty) vars['statusIn'] = statusIn;
    if (seasonYear != null) vars['seasonYear'] = seasonYear;

    final response = await _apiClient.postGraphQL(
      query: searchMediaQuery,
      variables: vars,
    );
    return response['Page'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> searchCharacters({
    required int page,
    int perPage = 20,
    String? search,
  }) async {
    final Map<String, dynamic> vars = {
      'page': page,
      'perPage': perPage,
    };
    if (search != null && search.isNotEmpty) vars['search'] = search;

    final response = await _apiClient.postGraphQL(
      query: searchCharacterQuery,
      variables: vars,
    );
    return response['Page'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> searchStaff({
    required int page,
    int perPage = 20,
    String? search,
  }) async {
    final Map<String, dynamic> vars = {
      'page': page,
      'perPage': perPage,
    };
    if (search != null && search.isNotEmpty) vars['search'] = search;

    final response = await _apiClient.postGraphQL(
      query: searchStaffQuery,
      variables: vars,
    );
    return response['Page'] as Map<String, dynamic>? ?? {};
  }
}
