# Security Policy

## Authentication & Token Storage

Mankai authenticates via AniList's official OAuth 2.0 flow inside an isolated WebView (`OAuthWebViewScreen`) and stores access tokens locally using `flutter_secure_storage` (Android Keystore / iOS Keychain). No credentials or tokens are transmitted to any third-party backend other than `https://anilist.co` and `https://graphql.anilist.co`.

## Reporting a Vulnerability

If you discover a security issue (such as token leakage, insecure storage, or deep-link hijacking), please report it responsibly by opening a private security advisory on GitHub or contacting the maintainer (`@tomi-prastiyo`) rather than posting sensitive exploit details in public issues.
