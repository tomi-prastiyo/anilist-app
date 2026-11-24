import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';

class OAuthWebViewScreen extends StatefulWidget {
  final Function(String token) onTokenReceived;

  const OAuthWebViewScreen({
    super.key,
    required this.onTokenReceived,
  });

  @override
  State<OAuthWebViewScreen> createState() => _OAuthWebViewScreenState();
}

class _OAuthWebViewScreenState extends State<OAuthWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasHandledToken = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
            _checkUrlForToken(url);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _checkUrlForToken(url);
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_checkUrlForToken(request.url)) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(ApiConstants.anilistAuthUrl));
  }

  bool _checkUrlForToken(String url) {
    if (_hasHandledToken) return true;

    if (url.contains('access_token=')) {
      final uri = Uri.parse(url);
      String? token;

      // Token can be in the fragment (#access_token=...) or query (?access_token=...)
      if (uri.hasFragment && uri.fragment.contains('access_token=')) {
        final params = Uri.splitQueryString(uri.fragment);
        token = params['access_token'];
      } else if (uri.queryParameters.containsKey('access_token')) {
        token = uri.queryParameters['access_token'];
      }

      if (token != null && token.isNotEmpty) {
        _hasHandledToken = true;
        // Safely pop this screen before notifying callback to prevent Navigator assertion crash
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        widget.onTokenReceived(token);
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login to AniList'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _isLoading
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.brandBlue,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
