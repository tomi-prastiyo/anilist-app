import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';
import 'rate_limiter.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final secureStorage = ref.watch(secureStorageServiceProvider);
  return ApiClient(secureStorage);
});

class ApiClient {
  final SecureStorageService _secureStorage;
  late final Dio _dio;

  ApiClient(this._secureStorage) {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.anilistGraphqlUrl,
        connectTimeout: ApiConstants.requestTimeout,
        receiveTimeout: ApiConstants.requestTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      RateLimitInterceptor(),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (err, handler) {
          // Wrap with clear error diagnostics
          handler.next(err);
        },
      ),
    ]);
  }

  /// Sends a GraphQL query or mutation to AniList.
  Future<Map<String, dynamic>> postGraphQL({
    required String query,
    Map<String, dynamic>? variables,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {'query': query};
      if (variables != null && variables.isNotEmpty) {
        requestBody['variables'] = variables;
      }

      final response = await _dio.post(
        '',
        data: requestBody,
      );

      final opLine = query.trim().split('\n').first.trim();
      if (opLine.contains('Toggle') || opLine.contains('CharacterQuery') || opLine.contains('StaffQuery')) {
        debugPrint('[GQL] $opLine vars=$variables -> ${response.data}');
      }

      final data = response.data;
      if (data is Map<String, dynamic>) {
        if (data.containsKey('errors') && data['errors'] != null) {
          final errors = data['errors'] as List<dynamic>;
          final firstError = errors.isNotEmpty ? errors.first['message'] : 'Unknown GraphQL error';
          throw ApiException(firstError.toString());
        }
        return (data['data'] as Map<String, dynamic>?) ?? {};
      }
      throw ApiException('Invalid response format received from AniList API');
    } on DioException catch (e) {
      if (e.response?.data != null && e.response?.data is Map) {
        final errorMsg = e.response?.data['errors']?[0]?['message'];
        if (errorMsg != null) {
          throw ApiException(errorMsg.toString());
        }
      }
      throw ApiException(e.message ?? 'Network error occurred while contacting AniList');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(e.toString());
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
