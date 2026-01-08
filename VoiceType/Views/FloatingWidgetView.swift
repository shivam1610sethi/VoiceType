import SwiftUI

/// The floating pill widget that shows dictation state
struct FloatingWidgetView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        ZStack {
            switch appState.recordingState {
            case .idle:
                IdlePillView(onTap: appState.startRecording)
                
            case .recording:
                RecordingPillView(
                    audioLevel: appState.audioLevel,
                    onCancel: appState.cancelRecording,
                    onStop: appState.stopRecording
                )
                
            case .transcribing:
                TranscribingPillView()
                
            case .error(let message):
                ErrorPillView(message: message, onDismiss: appState.dismissError)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appState.recordingState)
    }
}

// MARK: - Idle State

struct IdlePillView: View {
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                if isHovered {
                    HStack(spacing: 4) {
                        Text("Click or hold")
                            .foregroundColor(.white.opacity(0.8))
                        Text("fn")
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Text("to dictate")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .font(.system(size: 12, weight: .medium))
                } else {
                    Image(systemName: "waveform")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: isHovered ? 180 : 80, height: 44)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.85))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Recording State

struct RecordingPillView: View {
    let audioLevel: Float
    let onCancel: () -> Void
    let onStop: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Cancel button
            Button(action: onCancel) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .frame(width: 28, height: 28)
            .background(Circle().fill(Color.white.opacity(0.2)))
            
            // Audio waveform visualization
            HStack(spacing: 3) {
                ForEach(0..<8, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 3, height: waveHeight(for: index))
                }
            }
            .frame(width: 50, height: 24)
            
            // Stop/Finish button
            Button(action: onStop) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 28, height: 28)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white)
                        .frame(width: 12, height: 12)
                }
            }
            .buttonStyle(.plain)
        }
        .frame(height: 44)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
    
    private func waveHeight(for index: Int) -> CGFloat {
        let baseHeight: CGFloat = 6
        let maxAddition: CGFloat = 14
        let normalizedLevel = CGFloat(min(audioLevel * 3, 1.0))
        
        // Create pseudo-random wave pattern
        let heights: [CGFloat] = [0.3, 0.7, 0.5, 0.9, 0.6, 0.8, 0.4, 0.6]
        let wave = heights[index % heights.count]
        
        return baseHeight + (maxAddition * normalizedLevel * wave)
    }
}

// MARK: - Transcribing State

struct TranscribingPillView: View {
    @State private var animating = false
    
    var body: some View {
        HStack(spacing: 6) {
            Text("Transcribing")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 5, height: 5)
                        .opacity(animating ? 1 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 0.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 18)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
        .onAppear {
            animating = true
        }
    }
}

// MARK: - Error State

struct ErrorPillView: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white.opacity(0.7))
            
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)
        }
        .frame(height: 44)
        .padding(.horizontal, 14)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.9))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 30) {
        IdlePillView(onTap: {})
        RecordingPillView(audioLevel: 0.5, onCancel: {}, onStop: {})
        TranscribingPillView()
        ErrorPillView(message: "Microphone access denied", onDismiss: {})
    }
    .padding(50)
    .background(Color.gray.opacity(0.3))
}
