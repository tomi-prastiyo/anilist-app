<p align="center">
  <img src="assets/images/mankai_logo.png" width="140" alt="Mankai Logo" />
</p>

<h1 align="center">Mankai (満開)</h1>

<p align="center">
  <strong>Anime &amp; Manga Companion App powered by AniList</strong><br/>
  Inspired by <em>Yuuki Yuuna wa Yuusha de Aru</em> (Sanshu Hero Club)
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

### 💬 Activity Feed, Rich Bios & Details
- **Friends & Global Activity Feed**: Like/unlike activities & replies, view likes, delete your own activities, and compose comments via a redesigned keyboard-safe comment dock.
- **Rich AniList Bio Renderer & Editor**: Supports AniList HTML/Markdown formatting helpers, inline images, spoilers, and YouTube / `.webm` embeds.
- **Media, Character & Staff Details**: Rankings, trailers, AniSongDB OP/ED themes, voice actor & staff roles, and mutual friend scores.

---

## 🛠 Tech Stack

- **Framework**: Flutter & Dart (`sdk: ^3.11.5`)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Networking**: Dio + AniList GraphQL API (`graphql.anilist.co`) with rate-limit handling
- **Auth & Storage**: AniList OAuth WebView & personal token login via `flutter_secure_storage` & `shared_preferences`
- **Charts & Media**: `fl_chart`, `cached_network_image`, `shimmer`, `flutter_markdown`

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
