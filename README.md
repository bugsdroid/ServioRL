# ServioRL

Personal media server manager — Flutter app for Android.

Manage **Seerr, Sonarr, Radarr, Transmission & Bazarr** from one place, connected via Tailscale.

---

## Features

| Screen | Service | Status |
|---|---|---|
| Home | Dashboard | ✅ Done |
| Downloads | Transmission | ✅ Done |
| Requests | Seerr | ✅ Done |
| Search | Seerr | ✅ Done |
| Movies | Radarr | ✅ Done |
| TV Series | Sonarr | ✅ Done |
| Subtitles | Bazarr | ✅ Done |
| Settings | All services | ✅ Done |

---

## Key features per screen

### Home
- Service status cards (Seerr / Sonarr / Radarr / Transmission)
- Recent activity feed
- Download overview (Downloading / Seeding / Paused counts)
- Storage bar

### Downloads (Transmission)
- Tab filter: Downloading / Seeding / Paused
- Torrent card: name, teal progress bar, speed ↓↑, size, ETA
- Stalled badge (red) when peers = 0
- Pause / Play / Remove actions
- Remove dialog with "Delete files too" option

### Requests (Seerr)
- Tab: Seerr / Sonarr (TV) / Radarr (Movies)
- Count cards: Pending / Approved / Available — tap to filter
- Request card: TMDB poster, title, year, type badge, requested by, time ago
- Status badge: Pending (orange) / Approved (green) / Available (teal)

### Search (Seerr)
- Search bar with Movies / Series toggle
- Popular search chips
- Trending Movies + Trending Series horizontal poster grid
- Search results list with inline Request button
- Detail bottom sheet: backdrop, overview, rating, Request action

### Movies (Radarr)
- 3-column poster grid with quality badge + Missing overlay
- Filter: All / Downloaded / Missing / Monitored
- Sort: Title / Year / Size / Rating
- Movie detail: fanart header, meta, genres, overview
- Auto Search + Interactive Search
- Interactive Search screen: release list with quality, size, seeders, Grab button
- Remove movie action

### TV Series (Sonarr)
- 3-column poster grid with episode progress bar + ON AIR badge
- Filter: All / Airing / Ended / Missing / Monitored
- Sort: Title / Year / Episodes / Network
- Series detail: fanart header, episode progress, seasons list
- Season tile: expandable episode list with per-episode interactive search
- Episode interactive search: release list with Grab button

### Subtitles (Bazarr)
- Missing subtitles list (movies + episodes combined)
- Filter: All / Movies / Episodes
- Auto Search per item
- Manual Search: language picker → subtitle results
- Subtitle result card: release name, match score, provider, HI badge
- One-tap Download

### Settings
- Expandable service tiles: Seerr / Sonarr / Radarr / Transmission / Bazarr
- Connected / Setup badge per service
- General: Appearance, Notifications, About

---

## Tech stack

- **Flutter** (Dart) — Android
- **Riverpod** — state management
- **Dio** — HTTP client
- **go_router** — navigation
- **SharedPreferences** — config persistence
- **cached_network_image** — TMDB poster caching

---

## Setup

1. Clone repo & run `flutter pub get`
2. Open app → Settings
3. Enter Tailscale IP + port for each service:

| Service | Default port |
|---|---|
| Seerr | 5055 |
| Sonarr | 8989 |
| Radarr | 7878 |
| Transmission | 9091 |
| Bazarr | 6767 |

4. Enter API keys (found in each service Settings → API Key)
5. Transmission: username & password (optional, if auth enabled)

All services accessed directly via Tailscale IP — no reverse proxy needed.

---

## Project structure

```
lib/
├── main.dart
├── core/
│   ├── config/          # AppConfig model + Riverpod provider
│   ├── network/         # Dio clients + Transmission RPC client
│   ├── router/          # go_router setup
│   └── theme/           # Dark theme + AppColors
└── features/
    ├── home/            # Dashboard screen
    ├── downloads/       # Transmission — torrent_model, torrent_provider, downloads_screen
    ├── requests/        # Seerr — request_model, requests_provider, requests_screen
    ├── search/          # Seerr — search_model, search_provider, search_screen
    ├── movies/          # Radarr — movie_model, movies_provider, movies_screen
    ├── tv/              # Sonarr — tv_model, tv_provider, tv_screen
    ├── subtitles/       # Bazarr — subtitle_model, subtitles_provider, subtitles_screen
    ├── settings/        # Config screen
    └── widgets/         # Shared widgets (ServioRL logo)
```

---

## Build & run

```bash
git clone https://github.com/bugsdroid/ServioRL.git
cd ServioRL
flutter pub get
flutter run
```
