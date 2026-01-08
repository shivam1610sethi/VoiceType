import SwiftUI

/// Onboarding view for first-time permission setup - Sleek Black & White Design
struct OnboardingView: View {
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var speechRecognizer: SpeechRecognizer
    var onComplete: () -> Void
    
    var canContinue: Bool {
        permissionsManager.allPermissionsGranted && speechRecognizer.isReady
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header - Minimal & Compact
            VStack(spacing: 12) {
                // Icon - Simple black circle with waveform
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 4) {
                    Text("VoiceType")
                        .font(.system(size: 24, weight: .semibold))
                        .tracking(-0.3)
                    
                    Text("Voice to text, anywhere")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 20)
            
            // Scrollable content area
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 16) {
                    // Setup Steps
                    VStack(spacing: 8) {
                        // Microphone Permission
                        CompactPermissionRow(
                            icon: "mic",
                            title: "Microphone",
                            isGranted: permissionsManager.microphoneStatus == .granted,
                            buttonLabel: "Enable",
                            action: {
                                Task {
                                    await permissionsManager.requestMicrophonePermission()
                                }
                            }
                        )
                        
                        // Accessibility Permission
                        CompactPermissionRow(
                            icon: "accessibility",
                            title: "Accessibility",
                            isGranted: permissionsManager.accessibilityStatus == .granted,
                            buttonLabel: "Settings",
                            action: {
                                permissionsManager.openAccessibilitySettings()
                            }
                        )
                        
                        // AI Model
                        CompactModelRow(recognizer: speechRecognizer)
                    }
                    
                    // Help text for accessibility (only when needed)
                    if permissionsManager.accessibilityStatus != .granted {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("To enable Accessibility:")
                                .font(.system(size: 11, weight: .medium))
                            Text("Click Settings → Click + → Select VoiceType.app → Toggle ON")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.black.opacity(0.03))
                        )
                    }
                }
                .padding(.horizontal, 28)
            }
            .frame(maxHeight: .infinity)
            
            // Bottom Buttons - Fixed
            VStack(spacing: 8) {
                Button(action: onComplete) {
                    HStack(spacing: 6) {
                        Text("Get Started")
                            .font(.system(size: 14, weight: .medium))
                        
                        if canContinue {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                    }
                    .foregroundColor(canContinue ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(canContinue ? Color.black : Color.black.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canContinue)
                
                if !canContinue {
                    Button(action: onComplete) {
                        Text("Skip for now")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 20)
            .padding(.top, 12)
        }
        .frame(width: 340, height: 420)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            permissionsManager.checkAllPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionsManager.checkAllPermissions()
        }
    }
}

// MARK: - Compact Permission Row

struct CompactPermissionRow: View {
    let icon: String
    let title: String
    let isGranted: Bool
    let buttonLabel: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 18)
            
            // Title
            Text(title)
                .font(.system(size: 13, weight: .medium))
            
            Spacer()
            
            // Status/Action
            if isGranted {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(5)
                    .background(
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5)
                    )
            } else {
                Button(action: action) {
                    Text(buttonLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.black)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Compact Model Row

struct CompactModelRow: View {
    @ObservedObject var recognizer: SpeechRecognizer
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: "cpu")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 18)
            
            // Text
            VStack(alignment: .leading, spacing: 1) {
                Text("AI Model")
                    .font(.system(size: 13, weight: .medium))
                
                if let error = recognizer.initializationError {
                    Text("Download failed")
                        .font(.system(size: 10))
                        .foregroundColor(.red)
                } else if recognizer.isInitializing {
                    Text(recognizer.initializationProgress)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status
            if recognizer.isReady {
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(5)
                    .background(
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5)
                    )
            } else if recognizer.isInitializing {
                ProgressView()
                    .scaleEffect(0.6)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
            } else if recognizer.initializationError != nil {
                Button(action: {
                    Task {
                        await recognizer.initialize()
                    }
                }) {
                    Text("Retry")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .fill(Color.black)
                        )
                }
                .buttonStyle(.plain)
            } else {
                ProgressView()
                    .scaleEffect(0.6)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Preview

// Note: Preview disabled due to MainActor isolation requirements
