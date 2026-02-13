import SwiftUI
import UniformTypeIdentifiers

// Configuration UI for operations that need settings
struct OperationConfigView: View {
    let operation: Operation
    @Binding var config: OperationConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch operation {

            // MARK: - Audio with second file (file selection happens when clicking Process)
            case .replaceAudio:
                Text("Click Process to select the replacement audio file")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

            case .addAudioLayer:
                Text("Click Process to select the audio file to mix in")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

            // MARK: - Format conversion
            case .changeContainer:
                FormatPicker(
                    label: "Convert to:",
                    formats: ["mp4", "mov", "mkv"],
                    selection: Binding(
                        get: { config.targetFormat ?? "mp4" },
                        set: { config.targetFormat = $0 }
                    )
                )

            case .convertAudioFormat:
                FormatPicker(
                    label: "Convert to:",
                    formats: ["mp3", "aac", "wav", "flac", "m4a"],
                    selection: Binding(
                        get: { config.targetAudioFormat ?? "mp3" },
                        set: { config.targetAudioFormat = $0 }
                    )
                )

            // MARK: - Compression
            case .compress:
                PresetPicker(
                    label: "Quality:",
                    selection: $config.compressionPreset
                )

            // MARK: - ProRes
            case .convertToProRes:
                ProResPicker(
                    label: "Profile:",
                    selection: $config.proresProfile
                )

            // MARK: - Splitting
            case .splitByParts:
                NumberInput(
                    label: "Number of parts:",
                    value: $config.splitParts,
                    range: 2...100
                )

            case .splitBySeconds:
                NumberInput(
                    label: "Seconds per segment:",
                    value: $config.splitSeconds,
                    range: 1...3600
                )

            case .splitBySize:
                NumberInput(
                    label: "Target size (MB):",
                    value: $config.splitSizeMB,
                    range: 1...4096
                )

            // MARK: - Edit Operations
            case .trim:
                TrimInput(
                    trimStart: $config.trimStart,
                    trimEnd: $config.trimEnd
                )

            case .speedChange:
                SpeedPicker(selection: $config.speedMultiplier)

            // MARK: - Export Operations
            case .extractFrames:
                FrameExtractionConfig(config: $config)

            case .createGIF:
                GIFConfigView(config: $config)

            case .videoSummary:
                NumberInput(
                    label: "Target duration (seconds):",
                    value: $config.summaryDuration,
                    range: 5...300
                )

            case .contactSheet:
                ContactSheetConfig(config: $config)

            // MARK: - Additional Audio Operations
            case .adjustVolume:
                VolumeAdjustmentPicker(selection: $config.volumeAdjustment)

            case .enhanceAudio:
                EnhanceAudioPresetPicker(selection: $config.enhanceAudioPreset)

            // MARK: - Additional Format Operations
            case .resizeVideo:
                ResolutionPicker(selection: $config.targetResolution)

            case .createProxy:
                ProxyResolutionPicker(selection: $config.proxyResolution)

            // MARK: - Additional Edit Operations
            case .rotate:
                RotationPicker(selection: $config.rotationAngle)

            case .flip:
                FlipPicker(selection: $config.flipDirection)

            case .cropToVertical:
                CropPositionPicker(selection: $config.verticalCropPosition)

            // MARK: - Overlay Operations
            case .mergeVideos:
                MultiVideoFilePicker(selectedFiles: $config.videosToMerge)

            case .burnSubtitles:
                SubtitleFilePicker(selectedFile: $config.subtitleFile)

            case .pictureInPicture:
                PictureInPictureConfig(config: $config)

            // No config needed
            default:
                EmptyView()
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Config Components

// Pick a secondary file (for replace/add audio)
struct SecondaryFilePicker: View {
    let label: String
    @Binding var selectedFile: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                if let file = selectedFile {
                    Text(file.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("Change") {
                        pickFile()
                    }
                    .buttonStyle(.borderless)
                } else {
                    Button("Select Audio File...") {
                        pickFile()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.audio, .mp3, .wav, .aiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            selectedFile = panel.url
        }
    }
}

// Pick output format
struct FormatPicker: View {
    let label: String
    let formats: [String]
    @Binding var selection: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Picker("", selection: $selection) {
                ForEach(formats, id: \.self) { format in
                    Text(format.uppercased()).tag(format)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 200)
        }
    }
}

// Compression preset picker
struct PresetPicker: View {
    let label: String
    @Binding var selection: CompressionPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(CompressionPreset.allCases, id: \.self) { preset in
                PresetRow(
                    preset: preset,
                    isSelected: selection == preset
                ) {
                    selection = preset
                }
            }
        }
    }
}

struct PresetRow: View {
    let preset: CompressionPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(preset.rawValue)
                        .fontWeight(isSelected ? .medium : .regular)
                    Text(preset.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                }
            }
            .padding(10)
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }
}

// ProRes profile picker
struct ProResPicker: View {
    let label: String
    @Binding var selection: ProResProfile

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(ProResProfile.allCases, id: \.self) { profile in
                Button {
                    selection = profile
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(profile.rawValue)
                                .fontWeight(selection == profile ? .medium : .regular)
                            Text(profile.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selection == profile {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(10)
                    .background(selection == profile ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Number input for split options
struct NumberInput: View {
    let label: String
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 8) {
                Button {
                    if value > range.lowerBound {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle")
                }
                .buttonStyle(.borderless)
                .disabled(value <= range.lowerBound)

                TextField("", value: $value, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                    .multilineTextAlignment(.center)

                Button {
                    if value < range.upperBound {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus.circle")
                }
                .buttonStyle(.borderless)
                .disabled(value >= range.upperBound)
            }
        }
    }
}

// Time input for timestamps (in seconds)
struct TimeInput: View {
    let label: String
    @Binding var value: Double

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            TextField("", value: $value, format: .number)
                .textFieldStyle(.roundedBorder)
                .frame(width: 80)
                .multilineTextAlignment(.center)

            Text("sec")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Trim start/end input
struct TrimInput: View {
    @Binding var trimStart: Double
    @Binding var trimEnd: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Start time:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)

                TextField("", value: $trimStart, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.center)

                Text("seconds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("End time:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 80, alignment: .leading)

                TextField("", value: $trimEnd, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 80)
                    .multilineTextAlignment(.center)

                Text("seconds")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Leave end time at 0 to keep until the end")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Speed multiplier picker with manual input
struct SpeedPicker: View {
    @Binding var selection: Double
    @State private var customSpeedText: String = ""
    @FocusState private var isCustomFocused: Bool

    let speeds: [Double] = [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Manual input
            HStack {
                Text("Speed:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    TextField("", text: $customSpeedText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 70)
                        .multilineTextAlignment(.center)
                        .focused($isCustomFocused)
                        .onAppear {
                            customSpeedText = formatSpeed(selection)
                        }
                        .onChange(of: selection) { newValue in
                            if !isCustomFocused {
                                customSpeedText = formatSpeed(newValue)
                            }
                        }
                        .onSubmit {
                            applyCustomSpeed()
                        }

                    Text("x")
                        .foregroundColor(.secondary)
                }
            }

            // Preset buttons
            Text("Presets:")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(speeds, id: \.self) { speed in
                    Button {
                        selection = speed
                        customSpeedText = formatSpeed(speed)
                    } label: {
                        Text(speedLabel(speed))
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selection == speed ? Color.accentColor : Color(.controlBackgroundColor))
                            .foregroundColor(selection == speed ? .white : .primary)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            // Description
            Text(speedDescription(selection))
                .font(.caption)
                .foregroundColor(.secondary)

            // Help text
            Text("Enter any value from 0.1x to 100x")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func applyCustomSpeed() {
        // Remove 'x' suffix if present
        let cleaned = customSpeedText.replacingOccurrences(of: "x", with: "").trimmingCharacters(in: .whitespaces)
        if let value = Double(cleaned), value >= 0.1, value <= 100 {
            selection = value
        } else {
            // Reset to current selection if invalid
            customSpeedText = formatSpeed(selection)
        }
    }

    private func formatSpeed(_ speed: Double) -> String {
        if speed == floor(speed) {
            return String(format: "%.0f", speed)
        } else {
            return String(format: "%.2g", speed)
        }
    }

    private func speedLabel(_ speed: Double) -> String {
        if speed == 1.0 {
            return "1x"
        } else if speed < 1.0 {
            return String(format: "%.2gx", speed)
        } else {
            return String(format: "%.0fx", speed)
        }
    }

    private func speedDescription(_ speed: Double) -> String {
        if speed < 1.0 {
            return "Slow motion (\(Int((1.0/speed) * 100))% longer)"
        } else if speed > 1.0 {
            return "Sped up (\(Int(100/speed))% of original length)"
        } else {
            return "Original speed"
        }
    }
}

// GIF creation config
struct GIFConfigView: View {
    @Binding var config: OperationConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Start time:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)

                TextField("", value: $config.gifStart, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)

                Text("sec")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Duration:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)

                TextField("", value: $config.gifDuration, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)

                Text("sec")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Frame rate:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)

                Picker("", selection: $config.gifFPS) {
                    Text("10 fps").tag(10)
                    Text("15 fps").tag(15)
                    Text("20 fps").tag(20)
                    Text("30 fps").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }

            HStack {
                Text("Width:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 100, alignment: .leading)

                Picker("", selection: $config.gifWidth) {
                    Text("320px").tag(320)
                    Text("480px").tag(480)
                    Text("640px").tag(640)
                    Text("800px").tag(800)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 250)
            }

            Text("Smaller size & lower fps = smaller file")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Contact sheet config
struct ContactSheetConfig: View {
    @Binding var config: OperationConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Columns:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Picker("", selection: $config.contactSheetColumns) {
                    ForEach([2, 3, 4, 5, 6], id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }

            HStack {
                Text("Rows:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Picker("", selection: $config.contactSheetRows) {
                    ForEach([2, 3, 4, 5, 6], id: \.self) { n in
                        Text("\(n)").tag(n)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 200)
            }

            Text("Creates a \(config.contactSheetColumns)x\(config.contactSheetRows) grid (\(config.contactSheetColumns * config.contactSheetRows) thumbnails)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// Volume adjustment picker with manual input
struct VolumeAdjustmentPicker: View {
    @Binding var selection: Double
    @State private var customVolumeText: String = ""
    @FocusState private var isCustomFocused: Bool

    let volumes: [(value: Double, label: String)] = [
        (0.25, "25%"),
        (0.5, "50%"),
        (0.75, "75%"),
        (1.0, "100%"),
        (1.5, "150%"),
        (2.0, "200%"),
        (3.0, "300%")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Manual input
            HStack {
                Text("Volume level:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    TextField("", text: $customVolumeText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .multilineTextAlignment(.center)
                        .focused($isCustomFocused)
                        .onAppear {
                            customVolumeText = "\(Int(selection * 100))"
                        }
                        .onChange(of: selection) { newValue in
                            if !isCustomFocused {
                                customVolumeText = "\(Int(newValue * 100))"
                            }
                        }
                        .onSubmit {
                            applyCustomVolume()
                        }

                    Text("%")
                        .foregroundColor(.secondary)
                }
            }

            // Preset buttons
            Text("Presets:")
                .font(.caption)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(volumes, id: \.value) { vol in
                    Button {
                        selection = vol.value
                        customVolumeText = "\(Int(vol.value * 100))"
                    } label: {
                        Text(vol.label)
                            .font(.system(.body, design: .monospaced))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(selection == vol.value ? Color.accentColor : Color(.controlBackgroundColor))
                            .foregroundColor(selection == vol.value ? .white : .primary)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(volumeDescription)
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Enter any value from 1% to 1000%")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private func applyCustomVolume() {
        let cleaned = customVolumeText.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces)
        if let value = Double(cleaned), value >= 1, value <= 1000 {
            selection = value / 100.0
        } else {
            customVolumeText = "\(Int(selection * 100))"
        }
    }

    var volumeDescription: String {
        if selection < 1.0 {
            return "Reduce volume to \(Int(selection * 100))%"
        } else if selection > 1.0 {
            return "Boost volume to \(Int(selection * 100))%"
        } else {
            return "Keep original volume"
        }
    }
}

// Enhance audio preset picker
struct EnhanceAudioPresetPicker: View {
    @Binding var selection: EnhanceAudioPreset

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Enhancement level:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(EnhanceAudioPreset.allCases, id: \.self) { preset in
                Button {
                    selection = preset
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(preset.rawValue)
                                .fontWeight(selection == preset ? .medium : .regular)
                            Text(preset.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selection == preset {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(10)
                    .background(selection == preset ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            // Requirement note
            VStack(alignment: .leading, spacing: 4) {
                Text("Requires RNN denoise models:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("git clone https://github.com/richardpl/arnndn-models.git ~/arnndn-models")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
            .padding(.top, 8)
        }
    }
}

// Resolution picker with custom option
struct ResolutionPicker: View {
    @Binding var selection: String
    @State private var customWidth: String = ""
    @State private var isCustomMode = false

    let resolutions = ["2160p", "1080p", "720p", "480p", "360p"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target resolution:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Preset options
            ForEach(resolutions, id: \.self) { res in
                Button {
                    selection = res
                    isCustomMode = false
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(res)
                                .fontWeight(selection == res && !isCustomMode ? .medium : .regular)
                            Text(resolutionDescription(res))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selection == res && !isCustomMode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(10)
                    .background(selection == res && !isCustomMode ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            // Custom resolution option
            Button {
                isCustomMode = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Custom")
                            .fontWeight(isCustomMode ? .medium : .regular)
                        Text("Enter a specific width")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if isCustomMode {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(10)
                .background(isCustomMode ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
                .cornerRadius(6)
            }
            .buttonStyle(.plain)

            // Custom width input (shown when custom mode is active)
            if isCustomMode {
                HStack {
                    Text("Width:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    TextField("e.g. 1280", text: $customWidth)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .onSubmit {
                            applyCustomWidth()
                        }

                    Text("px")
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Apply") {
                        applyCustomWidth()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 4)

                Text("Height will be calculated to maintain aspect ratio")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func applyCustomWidth() {
        if let width = Int(customWidth), width >= 100, width <= 7680 {
            selection = "custom:\(width)"
        }
    }

    func resolutionDescription(_ res: String) -> String {
        switch res {
        case "2160p": return "4K Ultra HD (3840×2160)"
        case "1080p": return "Full HD (1920×1080)"
        case "720p": return "HD (1280×720)"
        case "480p": return "SD (854×480)"
        case "360p": return "Low (640×360)"
        default: return ""
        }
    }
}

// Rotation picker
struct RotationPicker: View {
    @Binding var selection: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Rotation:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach([90, 180, 270], id: \.self) { angle in
                    Button {
                        selection = angle
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: rotationIcon(angle))
                                .font(.title2)
                            Text("\(angle)°")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selection == angle ? Color.accentColor : Color(.controlBackgroundColor))
                        .foregroundColor(selection == angle ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    func rotationIcon(_ angle: Int) -> String {
        switch angle {
        case 90: return "rotate.right"
        case 180: return "arrow.up.arrow.down"
        case 270: return "rotate.left"
        default: return "rotate.right"
        }
    }
}

// Flip picker
struct FlipPicker: View {
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Flip direction:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                Button {
                    selection = "horizontal"
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.title2)
                        Text("Horizontal")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selection == "horizontal" ? Color.accentColor : Color(.controlBackgroundColor))
                    .foregroundColor(selection == "horizontal" ? .white : .primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)

                Button {
                    selection = "vertical"
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title2)
                        Text("Vertical")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selection == "vertical" ? Color.accentColor : Color(.controlBackgroundColor))
                    .foregroundColor(selection == "vertical" ? .white : .primary)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// Crop position picker for vertical crop
struct CropPositionPicker: View {
    @Binding var selection: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Crop from:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack(spacing: 12) {
                ForEach(["left", "center", "right"], id: \.self) { position in
                    Button {
                        selection = position
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: positionIcon(position))
                                .font(.title2)
                            Text(position.capitalized)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selection == position ? Color.accentColor : Color(.controlBackgroundColor))
                        .foregroundColor(selection == position ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Takes a vertical 9:16 slice from the selected region")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    func positionIcon(_ position: String) -> String {
        switch position {
        case "left": return "rectangle.lefthalf.inset.filled"
        case "right": return "rectangle.righthalf.inset.filled"
        default: return "rectangle.center.inset.filled"
        }
    }
}

// Multi-video file picker for merge
struct MultiVideoFilePicker: View {
    @Binding var selectedFiles: [URL]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Videos to merge (in order):")
                .font(.subheadline)
                .foregroundColor(.secondary)

            if !selectedFiles.isEmpty {
                ForEach(Array(selectedFiles.enumerated()), id: \.offset) { index, file in
                    HStack {
                        Text("\(index + 2).")
                            .foregroundColor(.secondary)
                            .frame(width: 24)
                        Text(file.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)
                        Spacer()
                        Button {
                            selectedFiles.remove(at: index)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(8)
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
            }

            Button("Add Video...") {
                pickVideos()
            }
            .buttonStyle(.bordered)

            Text("The dropped video will be first, then these in order")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private func pickVideos() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie, .avi]
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            selectedFiles.append(contentsOf: panel.urls)
        }
    }
}

// Subtitle file picker
struct SubtitleFilePicker: View {
    @Binding var selectedFile: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Subtitle file (.srt):")
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                if let file = selectedFile {
                    Text(file.lastPathComponent)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("Change") {
                        pickFile()
                    }
                    .buttonStyle(.borderless)
                } else {
                    Button("Select Subtitle File...") {
                        pickFile()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(12)
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func pickFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "srt")!]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            selectedFile = panel.url
        }
    }
}

// Picture in Picture config
struct PictureInPictureConfig: View {
    @Binding var config: OperationConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Video picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Overlay video:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack {
                    if let file = config.pipVideo {
                        Text(file.lastPathComponent)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        Button("Change") {
                            pickVideo()
                        }
                        .buttonStyle(.borderless)
                    } else {
                        Button("Select Video...") {
                            pickVideo()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(12)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }

            // Position picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Position:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(["top-left", "top-right", "bottom-left", "bottom-right"], id: \.self) { pos in
                        Button {
                            config.pipPosition = pos
                        } label: {
                            Text(pos.replacingOccurrences(of: "-", with: " ").capitalized)
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(config.pipPosition == pos ? Color.accentColor : Color(.controlBackgroundColor))
                                .foregroundColor(config.pipPosition == pos ? .white : .primary)
                                .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Size picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Size:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    ForEach(["small", "medium", "large"], id: \.self) { size in
                        Button {
                            config.pipSize = size
                        } label: {
                            VStack(spacing: 2) {
                                Text(size.capitalized)
                                Text(sizePercent(size))
                                    .font(.caption2)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(config.pipSize == size ? Color.accentColor : Color(.controlBackgroundColor))
                            .foregroundColor(config.pipSize == size ? .white : .primary)
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    func sizePercent(_ size: String) -> String {
        switch size {
        case "small": return "25%"
        case "medium": return "33%"
        case "large": return "50%"
        default: return ""
        }
    }

    private func pickVideo() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.movie, .mpeg4Movie, .quickTimeMovie, .avi]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK {
            config.pipVideo = panel.url
        }
    }
}

// Frame extraction configuration
struct FrameExtractionConfig: View {
    @Binding var config: OperationConfig

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Extraction method:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Mode picker
            ForEach(FrameExtractionMode.allCases, id: \.self) { mode in
                Button {
                    config.frameExtractionMode = mode
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(mode.rawValue)
                                .fontWeight(config.frameExtractionMode == mode ? .medium : .regular)
                            Text(mode.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if config.frameExtractionMode == mode {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(10)
                    .background(config.frameExtractionMode == mode ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            Divider()
                .padding(.vertical, 4)

            // Mode-specific options
            switch config.frameExtractionMode {
            case .totalFrames:
                NumberInput(
                    label: "Number of frames:",
                    value: $config.frameCount,
                    range: 1...1000
                )

            case .everyNSeconds:
                HStack {
                    Text("Extract every:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    TextField("", value: $config.frameIntervalSeconds, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .multilineTextAlignment(.center)

                    Text("seconds")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Quick presets
                HStack(spacing: 8) {
                    ForEach([0.5, 1.0, 2.0, 5.0, 10.0], id: \.self) { interval in
                        Button {
                            config.frameIntervalSeconds = interval
                        } label: {
                            Text(formatInterval(interval))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(config.frameIntervalSeconds == interval ? Color.accentColor : Color(.controlBackgroundColor))
                                .foregroundColor(config.frameIntervalSeconds == interval ? .white : .primary)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }

            case .everyNFrames:
                HStack {
                    Text("Extract every:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    TextField("", value: $config.frameIntervalFrames, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .multilineTextAlignment(.center)

                    Text("frames")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // Quick presets
                HStack(spacing: 8) {
                    ForEach([10, 24, 30, 60, 120], id: \.self) { interval in
                        Button {
                            config.frameIntervalFrames = interval
                        } label: {
                            Text("\(interval)")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(config.frameIntervalFrames == interval ? Color.accentColor : Color(.controlBackgroundColor))
                                .foregroundColor(config.frameIntervalFrames == interval ? .white : .primary)
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Text("At 30fps: every 30 frames = 1 per second")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func formatInterval(_ seconds: Double) -> String {
        if seconds < 1 {
            return "\(Int(seconds * 1000))ms"
        } else if seconds == 1 {
            return "1s"
        } else {
            return "\(Int(seconds))s"
        }
    }
}

// Proxy resolution picker
struct ProxyResolutionPicker: View {
    @Binding var selection: String

    let resolutions = [
        ("720p", "1280×720 - Good balance of quality and speed"),
        ("540p", "960×540 - Smaller files, faster editing"),
        ("480p", "854×480 - Smallest files, for slow machines")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Proxy resolution:")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ForEach(resolutions, id: \.0) { res, description in
                Button {
                    selection = res
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(res)
                                .fontWeight(selection == res ? .medium : .regular)
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if selection == res {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(10)
                    .background(selection == res ? Color.accentColor.opacity(0.1) : Color(.controlBackgroundColor))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }

            Text("Proxies use fast encoding for quick creation")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.top, 4)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        OperationConfigView(
            operation: .compress,
            config: .constant(OperationConfig())
        )

        Divider()

        OperationConfigView(
            operation: .splitByParts,
            config: .constant(OperationConfig())
        )
    }
    .padding()
    .frame(width: 350)
}
