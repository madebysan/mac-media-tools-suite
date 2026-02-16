# Media Tools Suite

A native macOS app for common video and audio processing tasks. Drag, drop, and go — with batch processing for multiple files at once.

No timelines, no complex UI — just quick conversions and edits powered by ffmpeg.

![Media Tools Suite — three-panel interface showing files, operations, and options](screenshot.png)

## Features

**31 operations across 6 categories:**

### Audio
- Remove audio from video
- Extract audio to separate file
- Replace audio track
- Add audio layer (mix/overlay)
- Normalize volume
- Convert audio format (MP3, WAV, AAC, etc.)
- Adjust volume (boost or reduce)
- Remove silence
- Enhance audio (denoise, EQ, normalize)

### Format
- Change container (MP4, MOV, MKV) — fast, no re-encoding
- Compress video (quality presets)
- Convert to ProRes
- Resize video (4K, 1080p, 720p, 480p, 360p, or custom)
- Create proxy — low-res copies for smoother editing

### Edit
- Trim (start to end time)
- Change speed (0.1x to 100x)
- Reverse
- Rotate (90, 180, 270)
- Flip / Mirror
- Crop to vertical (16:9 to 9:16)
- Black & White

### Split
- Split into X equal parts
- Split by duration (X seconds each)
- Split by file size (X MB each)

### Export
- Extract frames (by count, interval, or frame number)
- Create GIF
- Video summary (condense to short preview)
- Contact sheet (grid of thumbnails)

### Overlay
- Merge videos (combine multiple files)
- Burn subtitles (.srt hardcoded into video)
- Picture-in-Picture (with position and size options)

## How It Works

Three-panel interface:

1. **Files** (left) — Drop files or folders, toggle selection with checkboxes
2. **Operations** (middle) — Browse or search operations, star your favorites
3. **Options** (right) — Configure the selected operation

Click **Process** to run the operation on all selected files. Each operation translates to optimized ffmpeg commands that use stream copying when possible (fast, no quality loss).

## Supported Formats

**Video:** MP4, MOV, MKV, AVI, WebM, M4V
**Audio:** MP3, WAV, AAC, M4A, FLAC, OGG

## Requirements

- macOS 13.0 or later
- ffmpeg installed via Homebrew: `brew install ffmpeg`
- For Enhance Audio: `git clone https://github.com/richardpl/arnndn-models.git ~/arnndn-models`

## Installation

Download the latest DMG from the [Releases](https://github.com/madebysan/media-tools-suite/releases) page, open it, and drag **Media Tools Suite** to your Applications folder.

The app is signed and notarized with Apple Developer ID — no Gatekeeper warnings, installs and opens like any trusted Mac app.

## Building from Source

Open in Xcode:

```bash
open VideoAudioSuite.xcodeproj
```

Then build and run with **Cmd+R**.

Or build from the command line:

```bash
xcodebuild build \
  -project VideoAudioSuite.xcodeproj \
  -scheme VideoAudioSuite \
  -configuration Debug \
  -destination 'platform=macOS'
```

The built app will be named "Media Tools Suite".

## Running Tests

The project includes 141 unit tests and UI tests covering operation logic, state management, and UI flow.

Run all tests:

```bash
xcodebuild test \
  -project VideoAudioSuite.xcodeproj \
  -scheme VideoAudioSuite \
  -destination 'platform=macOS'
```

Run unit tests only:

```bash
xcodebuild test \
  -project VideoAudioSuite.xcodeproj \
  -scheme VideoAudioSuite \
  -destination 'platform=macOS' \
  -only-testing:VideoAudioSuiteTests
```

Run UI tests only:

```bash
xcodebuild test \
  -project VideoAudioSuite.xcodeproj \
  -scheme VideoAudioSuite \
  -destination 'platform=macOS' \
  -only-testing:VideoAudioSuiteUITests
```

## Project Structure

```
VideoAudioSuite/
├── VideoAudioSuiteApp.swift       # App entry point
├── ContentView.swift              # Main view router
├── Models/
│   ├── AppState.swift             # App state, batch file management
│   ├── BatchFile.swift            # File with selection/status
│   ├── FavoritesStore.swift       # Favorites persistence
│   ├── MediaFile.swift            # File representation
│   └── Operation.swift            # Operations & categories
├── Views/
│   ├── MainWorkspaceView.swift    # Three-panel layout
│   ├── FileListPanel.swift        # Left: file list with checkboxes
│   ├── OperationPanel.swift       # Middle: operations + search
│   ├── OperationListView.swift    # Flat operation list with stars
│   ├── OperationConfigView.swift  # Config UI components
│   ├── QueueBarView.swift         # Bottom: queue status + Process
│   ├── BatchProcessingView.swift  # Progress during batch
│   ├── BatchCompletionView.swift  # Results summary
│   └── CompletionView.swift       # Legacy completion view
└── Services/
    ├── FFmpegService.swift        # ffmpeg execution
    ├── OperationExecutor.swift    # Operation logic & config
    └── BatchExecutor.swift        # Sequential batch processing
```

## How to Add a New Operation

1. **`Operation.swift`** — Add a case to the `Operation` enum, update `name`, `description`, `outputSuffix`, `requiresSecondFile`, `requiresConfiguration`
2. **`OperationCategory`** — Add to the appropriate category's `operations(for:)` method
3. **`OperationExecutor.swift`** — Add config properties to `OperationConfig` if needed, add a case to `buildArguments`
4. **`OperationConfigView.swift`** — Add a case to the switch, create a config UI component

See `CLAUDE.md` for more detail on architecture, ffmpeg patterns, and testing.

## Contributing

Contributions are welcome! Here's how:

1. Fork the repository
2. Create a feature branch (`git checkout -b my-feature`)
3. Make your changes
4. Run the tests to make sure nothing is broken
5. Commit and push to your fork
6. Open a pull request

Please keep changes focused — one feature or fix per PR.

## License

[MIT](LICENSE)
