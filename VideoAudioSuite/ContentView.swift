import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @ObservedObject var batchExecutor = BatchExecutor.shared

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(.windowBackgroundColor), Color(.windowBackgroundColor).opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Main content
            if !appState.hasCheckedFFmpeg {
                // Still checking for ffmpeg
                ProgressView("Checking dependencies...")
                    .scaleEffect(0.8)
                    .accessibilityIdentifier("checkingDependencies")
            } else if !appState.ffmpegInstalled {
                // ffmpeg not installed - show instructions
                FFmpegMissingView()
                    .accessibilityIdentifier("ffmpegMissingView")
            } else {
                // Main workspace with processing state handling
                mainContent
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        switch appState.processingState {
        case .idle:
            // Show main workspace (file list + operations)
            MainWorkspaceView()

        case .processing:
            // Show batch processing progress
            if batchExecutor.isRunning {
                BatchProcessingView()
            } else {
                // Fallback to workspace if executor isn't running
                MainWorkspaceView()
            }

        case .completed, .error:
            // Show completion view
            BatchCompletionView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .frame(width: 700, height: 500)
}
