import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

final characterStaffRepositoryProvider = Provider<CharacterStaffRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CharacterStaffRepository(apiClient);
});

class CharacterStaffRepository {
  final ApiClient _apiClient;

  CharacterStaffRepository(this._apiClient);

  static const String characterQuery = r'''
    query CharacterQuery($id: Int) {
      Character(id: $id) {
        id
        name {
          first
          middle
          last
          full
          native
          userPreferred
        }
        image {
          large
          medium
        }
        description(asHtml: false)
        isFavourite
        media(perPage: 25, sort: [POPULARITY_DESC]) {
          edges {
            characterRole
            voiceActors(language: JAPANESE) {
              id
              name {
                userPreferred
              }
              image {
                medium
              }
            }
            node {
              id
              title {
                userPreferred
              }
              format
              coverImage {
                medium
              }
            }
          }
        }
      }
    }
  ''';

  static const String staffQuery = r'''
    query StaffQuery($id: Int) {
      Staff(id: $id) {
        id
        name {
          full
          native
          userPreferred
        }
        languageV2
        image {
          large
          medium
        }
        description(asHtml: false)
        primaryOccupations
        isFavourite
        characterMedia(perPage: 25, sort: [POPULARITY_DESC]) {
          edges {
            characters {
              id
              name {
                userPreferred
              }
              image {
                medium
              }
            }
            node {
              id
              title {
                userPreferred
              }
              format
              coverImage {
                medium
              }
            }
          }
        }
      }
    }
  ''';

  static const String studioQuery = r'''
    query StudioQuery($id: Int) {
      Studio(id: $id) {
        id
        name
        isFavourite
        media(sort: [POPULARITY_DESC], perPage: 25) {
          nodes {
            id
            title {
              userPreferred
            }
            format
            averageScore
            coverImage {
              large
              medium
            }
          }
        }
      }
    }
  ''';

  static const String toggleFavouriteMutation = r'''
    mutation ToggleFavourite($characterId: Int, $staffId: Int, $studioId: Int) {
      ToggleFavourite(characterId: $characterId, staffId: $staffId, studioId: $studioId) {
        characters {
          nodes {
            id
          }
        }
        staff {
          nodes {
            id
          }
        }
        studios {
          nodes {
            id
          }
        }
      }
    }
  ''';

  Future<Map<String, dynamic>> fetchCharacter(int id) async {
    final res = await _apiClient.postGraphQL(query: characterQuery, variables: {'id': id});
    return res['Character'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> fetchStaff(int id) async {
    final res = await _apiClient.postGraphQL(query: staffQuery, variables: {'id': id});
    return res['Staff'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> fetchStudio(int id) async {
    final res = await _apiClient.postGraphQL(query: studioQuery, variables: {'id': id});
    return res['Studio'] as Map<String, dynamic>? ?? {};
  }

  Future<void> toggleFavourite({int? characterId, int? staffId, int? studioId}) async {
    final Map<String, dynamic> vars = {};
    if (characterId != null) vars['characterId'] = characterId;
    if (staffId != null) vars['staffId'] = staffId;
    if (studioId != null) vars['studioId'] = studioId;

    await _apiClient.postGraphQL(
      query: toggleFavouriteMutation,
      variables: vars,
    );
  }
}
