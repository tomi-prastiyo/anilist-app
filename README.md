<p align="center">
  <img src="assets/images/mankai_logo.png" width="140" alt="Mankai Logo" />
</p>

<h1 align="center">Mankai (満開)</h1>

<p align="center">
  <strong>Anime &amp; Manga Companion App powered by AniList</strong><br/>
  Inspired by <em>Yuuki Yuuna wa Yuusha de Aru</em> (Sanshu Hero Club)
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter&logoColor=white" alt="Flutter" />
  <img src="https://img.shields.io/badge/Powered%20by-AniList-02A9FF?style=flat-square" alt="Powered by AniList" />
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-GPL--3.0-blue?style=flat-square" alt="License: GPL-3.0" /></a>
</p>

---

## ✨ Overview

**Mankai** is a modern Flutter client for [AniList](https://anilist.co) crafted with a *Yuuki Yuuna wa Yuusha de Aru* (**Mankai Sakura Twilight**) aesthetic alongside clean Dark, Light, and System themes. Track your anime & manga progress, manage your complete favorites collection, browse airing schedules tailored to your list, and engage with friends' activity feeds.

---

## 🌸 Key Features

### 🎨 Hero Club Themes & Visuals
- **YuYuYu • Mankai Theme**: Twilight plum-violet palette (`#120B1C`), drifting sakura petals overlay, and selectable Sanshu Hero Club companion accents (*Yuuna Yuuki*, *Mimori Tougou*, *Fuu Inubouzaki*, *Itsuki Inubouzaki*, *Karin Miyoshi*, and *Sonoko Nogi*).
- **Light, Dark & System Modes**: Crisp contrast and seamless theme transitions across Home, Lists, Stats charts, Bio views, and Comment sheets.

### 📺 Anime & Manga Tracking
- **Quick Progress Increments**:
  - **Anime**: Instant **`+1`** episode quick increment with airing behind badges.
  - **Manga & Light Novels**: Dual proportional quick-increment pills (**`+Ch`** for chapters & **`+Vol`** for volumes) across Home's *Manga In Progress* shelf and all Manga List views (*List*, *Compact*, and *Grid*).
- **Full List Editor**: Update status, score across all AniList scoring formats, progress, volumes, repeat count, dates, notes, and privacy.
- **Home Airing Today & Soon + Schedule**: Automatically filters airing episodes to titles in your Anime List (excluding 18+ entries).

### ❤️ Complete Favorites & Reordering
- **Full Paginated Favorites**: Loads your complete Anime, Manga, Characters, Staff, and Studios favorites beyond AniList's 25-item per-page limit.
- **Reorder Favorites (`UpdateFavouriteOrder`)**: Built-in drag-and-drop & one-tap **Move to #1 (`↑`)** sheet to rearrange your favorite positions directly from your Profile.
- **Real-Time Love Sync**: Synchronizes Love / Unlove toggles instantly across Anime, Manga, Character, Staff detail screens, and Profile Favorites.

### 💬 Activity Feed, Notifications & Rich Bios
- **Friends & Global Activity Feed**: Authenticated users can toggle between *Friends Only (Following)* and *Global* feeds, like/unlike activities & replies, view likes, delete their own activities, and compose comments via a keyboard-safe dock. Guest Mode defaults directly to a clean **Global-only** feed.
- **Notifications with Read / Unread Sync**: Live unread notification counter badge shared across Home and Profile, pull-to-refresh sync, dedicated **Unread** filter tab, per-notification **Mark Read / Mark Unread**, and one-tap **Mark all read**.
- **Rich AniList Bio Renderer & Editor**: Supports AniList HTML/Markdown formatting helpers, inline images, spoilers, and YouTube / `.webm` embeds.
- **Media, Character & Staff Details**: Rankings, trailers, AniSongDB OP/ED themes, voice actor & staff roles, and mutual friend scores.

---

## 🛠 Tech Stack

- **Framework**: Flutter & Dart (`sdk: ^3.11.5`)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Networking**: Dio + AniList GraphQL API (`graphql.anilist.co`) with rate-limit handling
- **Auth & Storage**: AniList OAuth WebView & Guest Mode via `flutter_secure_storage` & `shared_preferences`
- **Charts & Media**: `fl_chart`, `cached_network_image`, `shimmer`, `flutter_markdown`

---

## 🌟 Powered by AniList

**Mankai** is an unofficial third-party client **Powered by [AniList](https://anilist.co)** (`graphql.anilist.co`). All anime, manga, character, staff, airing, and community data is provided by the AniList GraphQL API v2.

---

## ⚖️ Community & Open-Source Attribution

- **UI & Feature Reference**: Design concepts, tracker workflows, and layout inspiration reference [**AL-chan**](https://github.com/zend10/AL-chan) (an unofficial Android AniList client licensed under the **GNU General Public License v3.0 / GPL-3.0**).
- **OAuth Client Note**: Development configuration currently mirrors an existing client ID for testing. Before publishing your own public distribution, register a dedicated application under [AniList Developer Settings](https://anilist.co/settings/developer) so users see **Mankai** on the OAuth consent prompt.

---

## 🚀 Getting Started

```bash
flutter pub get
flutter analyze lib/ test/
flutter test
flutter run
```

To build a debug or release APK:

```bash
flutter build apk --debug
# or
flutter build apk --release
```

### 🔐 OAuth Configuration for Public / Fork Builds

1. Register an application at [AniList Developer Settings](https://anilist.co/settings/developer).
2. Update `ApiConstants.anilistClientId` inside `lib/core/constants/api_constants.dart`.
3. Android package / application ID is configured as `com.tomiprastiyo.mankai` with custom callback schemes `mankai://` and `anilistapp://`.

---

## 🤝 Contributing & Policies

- [Contributing Guide](CONTRIBUTING.md)
- [Code of Conduct](CODE_OF_CONDUCT.md)
- [Security Policy](SECURITY.md)

---

## 📄 License & Disclaimer

Licensed under the [**GNU General Public License v3.0 (GPL-3.0)**](LICENSE).

**Mankai** is an unofficial third-party AniList client and is not affiliated with, endorsed by, or sponsored by **AniList** or **Studio Gokumi / Project 2H** (*Yuuki Yuuna wa Yuusha de Aru*). All user, anime, and manga data is fetched from the public AniList API.
