import AppKit
import AVFoundation
import ApplicationServices
import Combine

/// Manages checking and requesting all required permissions for VoiceType
@MainActor
class PermissionsManager: ObservableObject {
    @Published var microphoneStatus: PermissionStatus = .unknown
    @Published var accessibilityStatus: PermissionStatus = .unknown
    
    enum PermissionStatus: Equatable {
        case unknown
        case granted
        case denied
    }
    
    /// Returns true if all required permissions are granted
    var allPermissionsGranted: Bool {
        microphoneStatus == .granted && accessibilityStatus == .granted
    }
    
    init() {
        // Check permissions on init
        checkAllPermissions()
    }
    
    /// Check all permissions without prompting the user
    func checkAllPermissions() {
        checkMicrophonePermission()
        checkAccessibilityPermission()
        print("[PermissionsManager] Microphone: \(microphoneStatus), Accessibility: \(accessibilityStatus)")
    }
    
    // MARK: - Microphone Permission
    
    /// Check current microphone permission status
    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            microphoneStatus = .granted
        case .denied, .restricted:
            microphoneStatus = .denied
        case .notDetermined:
            microphoneStatus = .unknown
        @unknown default:
            microphoneStatus = .unknown
        }
    }
    
    /// Request microphone permission (shows system dialog)
    @discardableResult
    func requestMicrophonePermission() async -> Bool {
        let granted = await AVCaptureDevice.requestAccess(for: .audio)
        microphoneStatus = granted ? .granted : .denied
        return granted
    }
    
    // MARK: - Accessibility Permission
    
    /// Check current accessibility permission status
    func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        let newStatus: PermissionStatus = trusted ? .granted : .denied
        if newStatus != accessibilityStatus {
            accessibilityStatus = newStatus
            print("[PermissionsManager] AXIsProcessTrusted() changed to \(trusted)")
        }
    }
    
    /// Prompt user for accessibility permission (shows system alert with settings link)
    func promptForAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        // Re-check after a short delay (user might grant immediately)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.checkAccessibilityPermission()
        }
    }
    
    /// Open the Accessibility section in System Settings directly
    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        
        // Start polling for permission change
        startAccessibilityPolling()
    }
    
    /// Open the Microphone section in System Settings
    func openMicrophoneSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private var pollingTimer: Timer?
    
    /// Poll for accessibility permission changes (since there's no callback API)
    private func startAccessibilityPolling() {
        pollingTimer?.invalidate()
        
        // Poll every 0.5 seconds for 30 seconds
        var pollCount = 0
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            pollCount += 1
            self?.checkAccessibilityPermission()
            
            // Stop polling after 60 checks (30 seconds) or if granted
            if pollCount >= 60 || self?.accessibilityStatus == .granted {
                timer.invalidate()
                self?.pollingTimer = nil
            }
        }
    }
}
