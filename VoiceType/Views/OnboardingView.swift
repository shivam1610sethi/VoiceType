import SwiftUI

/// Onboarding view for first-time permission setup
struct OnboardingView: View {
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var speechRecognizer: SpeechRecognizer
    var onComplete: () -> Void
    
    var canContinue: Bool {
        permissionsManager.allPermissionsGranted && speechRecognizer.isReady
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text("VoiceType")
                    .font(.system(size: 32, weight: .bold))
                
                Text("Voice-to-text, anywhere on your Mac")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 32)
            
            Divider()
                .padding(.horizontal, 30)
            
            // Permission & Setup Steps
            VStack(spacing: 16) {
                Text("VoiceType needs a few things to get started:")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(.top, 20)
                
                VStack(spacing: 12) {
                    // Microphone Permission
                    PermissionRowView(
                        icon: "mic.fill",
                        iconColor: .pink,
                        title: "Microphone Access",
                        description: "To hear what you say",
                        status: permissionsManager.microphoneStatus,
                        actionLabel: "Enable",
                        action: {
                            Task {
                                await permissionsManager.requestMicrophonePermission()
                            }
                        }
                    )
                    
                    // Accessibility Permission
                    PermissionRowView(
                        icon: "hand.raised.fill",
                        iconColor: .blue,
                        title: "Accessibility Access",
                        description: "To type text and detect the Fn key",
                        status: permissionsManager.accessibilityStatus,
                        actionLabel: "Open Settings",
                        action: {
                            permissionsManager.openAccessibilitySettings()
                        }
                    )
                    
                    // Model Loading Status
                    ModelLoadingRowView(recognizer: speechRecognizer)
                }
                
                // Help text for accessibility
                if permissionsManager.accessibilityStatus != .granted {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("After opening Settings:")
                            .font(.system(size: 11, weight: .semibold))
                        Text("1. Click + to add VoiceType")
                            .font(.system(size: 11))
                        Text("2. Navigate to your Applications or Xcode build folder")
                            .font(.system(size: 11))
                        Text("3. Select VoiceType.app and toggle it ON")
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
                }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 20)
            
            Spacer()
            
            // Buttons
            VStack(spacing: 12) {
                // Continue Button
                Button(action: onComplete) {
                    HStack {
                        Text("Get Started")
                            .font(.system(size: 16, weight: .semibold))
                        
                        if canContinue {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(canContinue 
                                  ? LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                                  : LinearGradient(colors: [.gray, .gray], startPoint: .leading, endPoint: .trailing))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canContinue)
                
                // Skip button for development
                if !canContinue {
                    Button(action: onComplete) {
                        Text("Skip for now (limited functionality)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 30)
        }
        .frame(width: 480, height: 620)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            permissionsManager.checkAllPermissions()
        }
        // Re-check permissions when app becomes active
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionsManager.checkAllPermissions()
        }
    }
}

// MARK: - Permission Row

struct PermissionRowView: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    let status: PermissionsManager.PermissionStatus
    let actionLabel: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status/Action
            switch status {
            case .granted:
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    Text("Enabled")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
                
            case .denied, .unknown:
                Button(action: action) {
                    Text(actionLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(iconColor)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Model Loading Row

struct ModelLoadingRowView: View {
    @ObservedObject var recognizer: SpeechRecognizer
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "brain")
                    .font(.system(size: 20))
                    .foregroundColor(.purple)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 3) {
                Text("AI Model")
                    .font(.system(size: 14, weight: .semibold))
                Text(recognizer.isInitializing ? recognizer.initializationProgress : "For speech recognition")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status
            if recognizer.isReady {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.green)
                    Text("Ready")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.green)
                }
            } else if recognizer.isInitializing {
                ProgressView()
                    .scaleEffect(0.8)
            } else if let error = recognizer.initializationError {
                Text("Error")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.red)
            } else {
                Text("Waiting...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Preview

// Note: Preview disabled due to MainActor isolation requirements
