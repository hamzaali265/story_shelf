# StoryShelf

An offline-first M4B audiobook player for Android built with Flutter, Riverpod, and Hive.

<div align="center">
  <img src="assets/screenshots/home_screen.png" width="260" alt="Home Library Screen" />
  &nbsp;&nbsp;&nbsp;
  <img src="assets/screenshots/player_screen.png" width="260" alt="Full Player Screen" />
  &nbsp;&nbsp;&nbsp;
  <img src="assets/screenshots/chapters_screen.png" width="260" alt="Embedded M4B Chapter Picker" />
</div>

<br/>

## Highlights

- **M4B Chapter Parsing**: Extracts embedded Nero `chpl` atoms and QuickTime chapter text tracks directly from M4B files. Falls back to 30-minute auto-chapter division if no embedded markers exist.
- **Fast Media Scanning**: Uses a two-pass scanner. Performs an instant MediaStore query to render the library immediately (<50ms), then parses binary metadata in background `Isolate.run()` worker threads.
- **Strict Storage Filtering**: Scans strictly for `.m4b` files and `.m4a` files inside `/Audiobooks/` directories, filtering out general music tracks and ringtones.
- **Background Playback**: Full Android lock screen and notification media controls powered by `audio_service` and `just_audio`.
- **Offline Progress Tracking**: Remembers precise playback positions, playback speeds, and bookmarks per book using Hive local key-value storage.
- **Dynamic Cover Theme**: Generates background color gradients from audiobook cover artwork using `palette_generator`.

## Architecture

```
lib/
├── core/
│   ├── database/         # Hive initializers and playback state models
│   ├── models/           # Book, Chapter, PlaybackState, AppSettings data classes
│   ├── native_bridge/    # Android MediaStore Kotlin MethodChannel interface
│   ├── services/         # AudiobookAudioHandler extending AudioHandler
│   ├── theme/            # AppTheme dark mode palette and design system
│   └── utils/            # M4bParser, TimeFormatter, SmoothPageRoute
└── features/
    ├── bookmarks/        # Bookmark models, providers, and sheets
    ├── chapters/         # Modal chapter selection sheet
    ├── library/          # LibraryScreen, BookCard, ContinueListeningCard, ShimmerLoading
    ├── player/           # PlayerScreen, MiniPlayer, ScrubberBar, Speed & Sleep dialogs
    ├── search/           # Real-time search filter
    └── settings/         # App settings screen and speed defaults
```

## Tech Stack

| Dependency | Purpose |
|---|---|
| `flutter_riverpod` | State management and provider injection |
| `hive` / `hive_flutter` | Fast NoSQL storage for progress tracking and settings |
| `just_audio` + `audio_service` | Background audio engine & lock screen notifications |
| `palette_generator` | Dynamic color extraction from cover art |
| `permission_handler` | Storage and notification permission management |

## Getting Started

### Prerequisites

- Flutter SDK `>=3.3.0`
- Android SDK API 24+ (Android 7.0+)

### Building and Running

1. Clone the repository:
   ```bash
   git clone git@github.com:hamzaali265/story_shelf.git
   cd story_shelf
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run on a connected Android device:
   ```bash
   flutter run
   ```

4. Run unit tests:
   ```bash
   flutter test
   ```

## License

This project is licensed under the [MIT License](LICENSE).
