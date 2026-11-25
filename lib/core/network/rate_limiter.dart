import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

/// Ensures outgoing API calls never exceed AniList's 90 requests/minute rate limit.
class RateLimitInterceptor extends Interceptor {
  final List<DateTime> _requestTimestamps = [];
  Completer<void>? _rateLimitPause;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // If we are currently paused due to HTTP 429
    if (_rateLimitPause != null && !_rateLimitPause!.isCompleted) {
      await _rateLimitPause!.future;
    }

    final now = DateTime.now();
    _requestTimestamps.removeWhere((t) => now.difference(t) > const Duration(minutes: 1));

    if (_requestTimestamps.length >= ApiConstants.maxRequestsPerMinute) {
      final oldest = _requestTimestamps.first;
      final waitMs = 60000 - now.difference(oldest).inMilliseconds + 200;
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }

    _requestTimestamps.add(DateTime.now());
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _checkHeaders(response.headers);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 429) {
      final retryAfterHeader = err.response?.headers.value('retry-after');
      final retrySeconds = int.tryParse(retryAfterHeader ?? '') ?? 60;
      
      _rateLimitPause = Completer<void>();
      Future.delayed(Duration(seconds: retrySeconds), () {
        if (_rateLimitPause != null && !_rateLimitPause!.isCompleted) {
          _rateLimitPause!.complete();
        }
      });

      await _rateLimitPause!.future;

      // Retry the failed request
      try {
        final retryResponse = await Dio().fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (e) {
        return handler.next(err);
      }
    }

    handler.next(err);
  }

  void _checkHeaders(Headers headers) {
    final remaining = int.tryParse(headers.value('x-ratelimit-remaining') ?? '');
    if (remaining != null && remaining < 5) {
      // Small pause if getting close to API ceiling
      Future.delayed(const Duration(milliseconds: 500));
    }
  }
}
