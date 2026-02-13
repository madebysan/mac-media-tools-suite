import SwiftUI

// Full-screen view shown during batch processing
struct BatchProcessingView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var batchExecutor = BatchExecutor.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Main progress indicator
            VStack(spacing: 16) {
                // Animated processing icon
                ZStack {
                    Circle()
                        .stroke(Color.accentColor.opacity(0.2), lineWidth: 8)
                        .frame(width: 80, height: 80)

                    Circle()
                        .trim(from: 0, to: batchExecutor.currentProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.2), value: batchExecutor.currentProgress)

                    Image(systemName: "film")
                        .font(.system(size: 28))
                        .foregroundColor(.accentColor)
                }

                // File counter
                Text("Processing \(batchExecutor.currentIndex + 1) of \(batchExecutor.totalFiles)")
                    .font(.headline)

                // Current file name
                Text(batchExecutor.currentFileName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .padding(.horizontal, 40)
            }

            // Progress bars
            VStack(spacing: 12) {
                // Current file progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Current file")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(batchExecutor.currentProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: batchExecutor.currentProgress)
                        .progressViewStyle(.linear)
                }

                // Overall progress
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Overall")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(batchExecutor.overallProgress * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: batchExecutor.overallProgress)
                        .progressViewStyle(.linear)
                        .tint(.green)
                }
            }
            .padding(.horizontal, 60)
            .frame(maxWidth: 400)

            // Results so far
            if batchExecutor.successCount > 0 || batchExecutor.failureCount > 0 {
                HStack(spacing: 24) {
                    if batchExecutor.successCount > 0 {
                        Label("\(batchExecutor.successCount) completed", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                    if batchExecutor.failureCount > 0 {
                        Label("\(batchExecutor.failureCount) failed", systemImage: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }

            Spacer()

            // Cancel button
            Button {
                cancelProcessing()
            } label: {
                Label("Cancel", systemImage: "xmark")
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.windowBackgroundColor))
    }

    private func cancelProcessing() {
        batchExecutor.cancel()
        appState.processingState = .idle
    }
}

#Preview {
    BatchProcessingView()
        .environmentObject(AppState())
        .frame(width: 500, height: 400)
}
