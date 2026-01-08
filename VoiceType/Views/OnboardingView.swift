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
            // Header - Minimal
            VStack(spacing: 16) {
                // Icon - Simple black circle with waveform
                ZStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: "waveform")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white)
                }
                
                VStack(spacing: 6) {
                    Text("VoiceType")
                        .font(.system(size: 28, weight: .semibold, design: .default))
                        .tracking(-0.5)
                    
                    Text("Voice to text, anywhere on your Mac")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 48)
            .padding(.bottom, 36)
            
            // Setup Steps
            VStack(spacing: 10) {
                Text("Setup")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
                
                VStack(spacing: 8) {
                    // Microphone Permission
                    MinimalPermissionRow(
                        icon: "mic",
                        title: "Microphone",
                        subtitle: "To hear what you say",
                        isGranted: permissionsManager.microphoneStatus == .granted,
                        buttonLabel: "Enable",
                        action: {
                            Task {
                                await permissionsManager.requestMicrophonePermission()
                            }
                        }
                    )
                    
                    // Accessibility Permission
                    MinimalPermissionRow(
                        icon: "accessibility",
                        title: "Accessibility",
                        subtitle: "To type text and detect the Fn key",
                        isGranted: permissionsManager.accessibilityStatus == .granted,
                        buttonLabel: "Open Settings",
                        action: {
                            permissionsManager.openAccessibilitySettings()
                        }
                    )
                    
                    // AI Model
                    MinimalModelRow(recognizer: speechRecognizer)
                }
            }
            .padding(.horizontal, 36)
            
            // Help text for accessibility
            if permissionsManager.accessibilityStatus != .granted {
                VStack(alignment: .leading, spacing: 6) {
                    Text("After opening Settings:")
                        .font(.system(size: 11, weight: .medium))
                    Text("1. Click + to add VoiceType\n2. Navigate to Applications folder\n3. Select VoiceType.app and toggle ON")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )
                .padding(.horizontal, 36)
                .padding(.top, 12)
            }
            
            Spacer()
            
            // Bottom Buttons
            VStack(spacing: 10) {
                // Main CTA Button
                Button(action: onComplete) {
                    HStack(spacing: 8) {
                        Text("Get Started")
                            .font(.system(size: 15, weight: .medium))
                        
                        if canContinue {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                    }
                    .foregroundColor(canContinue ? .white : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(canContinue ? Color.black : Color.black.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!canContinue)
                
                // Skip button
                if !canContinue {
                    Button(action: onComplete) {
                        Text("Skip for now (limited functionality)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 36)
            .padding(.bottom, 32)
        }
        .frame(width: 380, height: 460)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            permissionsManager.checkAllPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            permissionsManager.checkAllPermissions()
        }
    }
}

// MARK: - Minimal Permission Row

struct MinimalPermissionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let isGranted: Bool
    let buttonLabel: String
    let action: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 20)
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Status/Action
            if isGranted {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(6)
                    .background(
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5)
                    )
            } else {
                Button(action: action) {
                    Text(buttonLabel)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Minimal Model Row

struct MinimalModelRow: View {
    @ObservedObject var recognizer: SpeechRecognizer
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            Image(systemName: "cpu")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
                .frame(width: 20)
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Model")
                    .font(.system(size: 14, weight: .medium))
                
                if let error = recognizer.initializationError {
                    Text(error)
                        .font(.system(size: 11))
                        .foregroundColor(.red)
                        .lineLimit(2)
                } else {
                    Text(recognizer.isInitializing ? recognizer.initializationProgress : "For speech recognition")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Status
            if recognizer.isReady {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(6)
                    .background(
                        Circle()
                            .stroke(Color.black, lineWidth: 1.5)
                    )
            } else if recognizer.isInitializing {
                ProgressView()
                    .scaleEffect(0.7)
                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
            } else if recognizer.initializationError != nil {
                Button(action: {
                    Task {
                        await recognizer.initialize()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                        Text("Retry")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.black)
                    )
                }
                .buttonStyle(.plain)
            } else {
                Text("...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Preview

// Note: Preview disabled due to MainActor isolation requirements
