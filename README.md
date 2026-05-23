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
| Settings | All services | ✅ Done |
| Movies | Radarr | 🔄 Next |
| TV Series | Sonarr | 🔄 Next |
| Subtitles | Bazarr | 🔄 Next |

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
- Count cards: Pending / Approved / Available (tap to filter)
- Request card: TMDB poster, title, year, type badge, requested by, time ago
- Status badge: Pending (orange) / Approved (green) / Available (teal)

### Search (Seerr)
- Search bar with Movies / Series toggle
- Popular search chips
- Trending Movies + Trending Series horizontal poster grid
- Search results list with Request button
- Detail bottom sheet: backdrop, overview, rating, Request action

### Settings
- Expandable service tiles: Seerr / Sonarr / Radarr / Transmission / Bazarr
- Connected / Setup badge per service
- General: Appearance, Notifications, About

## Tech stack

- **Flutter** (Dart) — Android
- **Riverpod** — state management
- **Dio** — HTTP client
- **go_router** — navigation
- **SharedPreferences** — config persistence
- **cached_network_image** — TMDB poster caching

## Setup

1. Clone repo & run `flutter pub get`
2. Open app → Settings (gear icon)
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
    ├── downloads/       # Transmission torrent manager
    │   ├── torrent_model.dart
    │   ├── torrent_provider.dart
    │   └── downloads_screen.dart
    ├── requests/        # Seerr request manager
    │   ├── request_model.dart
    │   ├── requests_provider.dart
    │   └── requests_screen.dart
    ├── search/          # Seerr search + trending
    │   ├── search_model.dart
    │   ├── search_provider.dart
    │   └── search_screen.dart
    ├── settings/        # Config screen
    └── widgets/         # Shared widgets (ServioRL logo)
```

## Development status

- [x] Project scaffold & routing
- [x] Dark theme (background #0F1117, accent teal #00D4AA)
- [x] ServioRL logo widget
- [x] Bottom nav: Home / Downloads / Requests / Search / Settings
- [x] Home screen — dashboard
- [x] Downloads screen — Transmission full UI
- [x] Requests screen — Seerr full UI
- [x] Search screen — Seerr full UI
- [x] Settings screen — all 5 services
- [ ] Movies screen — Radarr (library + interactive search)
- [ ] TV screen — Sonarr (library + per-episode search)
- [ ] Subtitles screen — Bazarr (manual search & select)

## Build & run

```bash
git clone https://github.com/bugsdroid/ServioRL.git
cd ServioRL
flutter pub get
flutter run
```
