import AppKit

/// Controls the menu bar status item and dropdown menu
@MainActor
class MenuBarController {
    private var statusItem: NSStatusItem?
    private weak var appState: AppState?
    
    /// Callback when "Copy Last Transcription" is clicked
    var onCopyLastTranscription: (() -> Void)?
    
    /// Callback when "Settings" is clicked
    var onOpenSettings: (() -> Void)?
    
    /// Callback when widget visibility is toggled
    var onToggleWidget: ((Bool) -> Void)?
    
    private var widgetVisible = true
    private var hasTranscription = false
    
    /// Set up the menu bar status item
    func setup(appState: AppState) {
        self.appState = appState
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "VoiceType")
            button.image?.isTemplate = true
        }
        
        buildMenu()
    }
    
    /// Update the menu bar icon based on recording state
    func updateIcon(isRecording: Bool) {
        guard let button = statusItem?.button else { return }
        
        if isRecording {
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "VoiceType - Recording")
            button.image?.isTemplate = false
            button.contentTintColor = .systemRed
        } else {
            button.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "VoiceType")
            button.image?.isTemplate = true
            button.contentTintColor = nil
        }
    }
    
    /// Rebuild the menu (call after transcription is available)
    func refreshMenu() {
        hasTranscription = appState?.lastTranscription != nil
        buildMenu()
    }
    
    private func buildMenu() {
        let menu = NSMenu()
        
        // Status row (not clickable)
        let statusItem = NSMenuItem(title: "VoiceType", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        if let image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: nil) {
            image.isTemplate = false
            statusItem.image = image
        }
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Copy last transcription
        let copyItem = NSMenuItem(
            title: hasTranscription ? "Copy Last Transcription" : "No Transcription Yet",
            action: #selector(copyLastTranscription),
            keyEquivalent: "c"
        )
        copyItem.keyEquivalentModifierMask = [.command, .shift]
        copyItem.target = self
        copyItem.isEnabled = hasTranscription
        menu.addItem(copyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Show/Hide Widget
        let widgetItem = NSMenuItem(
            title: widgetVisible ? "Hide Floating Widget" : "Show Floating Widget",
            action: #selector(toggleWidget),
            keyEquivalent: ""
        )
        widgetItem.target = self
        menu.addItem(widgetItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(
            title: "Quit VoiceType",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.statusItem?.menu = menu
    }
    
    // MARK: - Actions
    
    @objc private func copyLastTranscription() {
        onCopyLastTranscription?()
        
        // Show brief feedback via menu rebuild
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.buildMenu()
        }
    }
    
    @objc private func toggleWidget() {
        widgetVisible.toggle()
        onToggleWidget?(widgetVisible)
        buildMenu()
    }
    
    @objc private func openSettings() {
        onOpenSettings?()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
