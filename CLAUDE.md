# Video Audio Suite — Project Instructions

## Overview

A native SwiftUI macOS app that wraps ffmpeg for common video/audio processing tasks. Three-panel interface with batch processing support.

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI (macOS 13+)
- **Backend:** ffmpeg via Process (CLI execution)
- **Architecture:** MVVM with ObservableObject

## Project Structure

```
VideoAudioSuite/
├── Models/          # Data models and enums
├── Views/           # SwiftUI views
├── Services/        # ffmpeg execution and batch processing
└── Assets.xcassets/ # App icons
```

## Key Files

| File | Purpose |
|------|---------|
| `AppState.swift` | Global state, file management, ffmpeg detection |
| `BatchFile.swift` | File with selection state and processing status |
| `FavoritesStore.swift` | Persists favorite operations to UserDefaults |
| `Operation.swift` | All operations, categories, names, descriptions |
| `OperationExecutor.swift` | ffmpeg command building, config options |
| `BatchExecutor.swift` | Sequential batch processing with progress |
| `MainWorkspaceView.swift` | Three-panel layout (Files \| Operations \| Options) |
| `OperationConfigView.swift` | UI components for each operation's settings |
| `QueueBarView.swift` | Bottom bar with queue status and Process button |
| `FFmpegService.swift` | Process execution, progress parsing |

## UI Architecture

Three-panel layout:
1. **FileListPanel** (left): Drag-drop zone, file list with checkboxes
2. **OperationPanel** (middle): Search bar, favorites chips, operation list
3. **ConfigPanel** (right): Options for selected operation

Bottom bar (QueueBarView): Shows selected file count, operation, and Process button.

## Adding a New Operation

1. **Operation.swift:** Add case to `Operation` enum, update `name`, `description`, `outputSuffix`, `requiresSecondFile`, `requiresConfiguration`
2. **OperationCategory:** Add to appropriate category's `operations(for:)` method
3. **OperationExecutor.swift:** Add config properties to `OperationConfig` if needed, add case to `buildArguments` switch
4. **OperationConfigView.swift:** Add case to switch, create config UI component if needed

## ffmpeg Patterns

- Use `-c copy` for stream copying (fast, no re-encode)
- Use `-c:v copy` to copy video, re-encode audio (or vice versa)
- Use `-vf` for video filters, `-af` for audio filters
- Use `-filter_complex` for multi-input operations
- Always use `-y` to overwrite output

## Batch Processing Flow

1. User drops files/folders → `AppState.addFiles()` creates `BatchFile` entries
2. User selects files via checkboxes → `BatchFile.isSelected`
3. User picks operation → `AppState.selectedOperation`
4. User configures options → `AppState.operationConfig`
5. User clicks Process → `QueueBarView.startProcessing()`
6. `BatchExecutor` processes files sequentially, updates progress
7. Results shown in `BatchCompletionView`

## Operations Requiring External Files

Some operations prompt for a file when clicking Process:
- **Replace Audio / Add Audio Layer**: Opens audio file picker
- **Burn Subtitles**: Requires .srt file (selected in config panel)
- **Picture in Picture**: Requires overlay video (selected in config panel)
- **Merge Videos**: Requires additional videos (selected in config panel)

## Testing

### Automated Tests (141 unit tests + UI tests)

Run all tests:
```bash
xcodebuild test -project VideoAudioSuite.xcodeproj -scheme VideoAudioSuite -destination 'platform=macOS'
```

Run unit tests only:
```bash
xcodebuild test -project VideoAudioSuite.xcodeproj -scheme VideoAudioSuite -destination 'platform=macOS' -only-testing:VideoAudioSuiteTests
```

Run UI tests only:
```bash
xcodebuild test -project VideoAudioSuite.xcodeproj -scheme VideoAudioSuite -destination 'platform=macOS' -only-testing:VideoAudioSuiteUITests
```

Or use the `/qa-swift` skill in Claude Code for one-command build + test.

**Test files:**
| File | Tests | What it covers |
|------|-------|----------------|
| `OperationExecutorTests.swift` | All 31 operations' ffmpeg arg generation | Correct flags, output URLs, config values |
| `OperationTests.swift` | Enum metadata, categories, availability | Operation count, names, requiresSecondFile, category filtering |
| `MediaFileTests.swift` | Format validation, computed properties | Accepts/rejects file types, formattedDuration, formattedSize |
| `AppStateTests.swift` | State transitions, selection logic | canProcess, selectAll, clearFiles, operation compatibility |
| `FavoritesStoreTests.swift` | Persistence, toggle behavior | UserDefaults round-trip, add/remove/toggle |
| `VideoAudioSuiteUITests.swift` | UI flow automation | App launch, panel layout, search, process button state |

### Manual testing (for features tests can't cover):
1. Drop test video/audio files
2. Test single file and batch processing
3. Verify output files are created and playable

## Known Limitations

- Sandbox is disabled (required for file access)
- Progress bar is approximate (based on duration)
- Merge videos requires same codec/resolution for best results
- Some filters require re-encoding (slower)
- Operations requiring second file only work with single file selection

## Future Considerations

- Parallel processing option (for quick operations)
- Folder watching / auto-processing
- Whisper transcription integration
- Custom ffmpeg command mode
