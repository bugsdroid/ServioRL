# ServioRL

Personal media server manager — Flutter app for Android.

Manage **Sonarr, Radarr, Overseerr, Transmission & Bazarr** from one place, connected via Tailscale.

---

## Features

| Screen | Service | Key actions |
|---|---|---|
| Discover | Overseerr | Search & request films/series |
| Movies | Radarr | Library, interactive search, grab |
| TV Series | Sonarr | Library, per-episode search, grab |
| Downloads | Transmission | List torrents, stop/start/remove |
| Subtitles | Bazarr | Manual search & select subtitles |

## Tech stack

- **Flutter** (Dart) — Android
- **Riverpod** — state management
- **Dio** — HTTP client
- **go_router** — navigation
- **SharedPreferences** — settings persistence

## Setup

1. Clone repo & run `flutter pub get`
2. Open app → Settings (gear icon)
3. Enter Tailscale IP + port for each service
4. Enter API keys (found in each service's settings page)

All services are accessed directly via Tailscale IP — no reverse proxy needed.

## Project structure

```
lib/
├── main.dart
├── core/
│   ├── config/          # AppConfig model + Riverpod provider
│   ├── network/         # Dio clients + Transmission RPC client
│   ├── router/          # go_router setup
│   └── theme/           # Material 3 light/dark theme
└── features/
    ├── home/            # Bottom nav shell
    ├── discover/        # Overseerr screen
    ├── movies/          # Radarr screen
    ├── tv/              # Sonarr screen
    ├── downloads/       # Transmission screen
    ├── subtitles/       # Bazarr screen
    └── settings/        # Config screen
```

## Development status

- [x] Project scaffold & routing
- [x] Settings screen (all 5 services)
- [x] HTTP clients (Dio + Transmission RPC)
- [ ] Downloads screen (Transmission)
- [ ] Movies screen (Radarr)
- [ ] TV screen (Sonarr)
- [ ] Discover screen (Overseerr)
- [ ] Subtitles screen (Bazarr)
