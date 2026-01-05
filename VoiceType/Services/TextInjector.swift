import AppKit
import Carbon.HIToolbox

/// Injects text at the current cursor position using clipboard + simulated Cmd+V paste
class TextInjector {
    
    /// Stored clipboard content to restore after paste
    private var savedPasteboardChangeCount: Int = 0
    private var savedPasteboardData: [(NSPasteboard.PasteboardType, Data)] = []
    
    /// Inject text at the current cursor position
    /// Works by temporarily placing text on clipboard, simulating Cmd+V, then restoring clipboard
    func injectText(_ text: String) {
        guard !text.isEmpty else {
            print("[TextInjector] Empty text, skipping injection")
            return
        }
        
        print("[TextInjector] Injecting text: \(text.prefix(50))...")
        
        // 1. Save current clipboard content
        saveClipboard()
        
        // 2. Put our text on clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 3. Small delay to ensure clipboard is updated
        usleep(50000) // 50ms
        
        // 4. Simulate Cmd+V paste
        simulatePaste()
        
        // 5. Restore original clipboard after paste completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.restoreClipboard()
        }
    }
    
    /// Copy text to clipboard without pasting (for "Copy Last Transcription" feature)
    func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        print("[TextInjector] Copied to clipboard: \(text.prefix(50))...")
    }
    
    // MARK: - Private Methods
    
    private func saveClipboard() {
        let pasteboard = NSPasteboard.general
        savedPasteboardChangeCount = pasteboard.changeCount
        savedPasteboardData = []
        
        // Save all types of data on the clipboard
        if let items = pasteboard.pasteboardItems {
            for item in items {
                for type in item.types {
                    if let data = item.data(forType: type) {
                        savedPasteboardData.append((type, data))
                    }
                }
            }
        }
    }
    
    private func restoreClipboard() {
        guard !savedPasteboardData.isEmpty else { return }
        
        let pasteboard = NSPasteboard.general
        
        // Only restore if we haven't had other clipboard changes
        // (user might have copied something else)
        pasteboard.clearContents()
        
        // Create a new pasteboard item with all saved data
        let item = NSPasteboardItem()
        for (type, data) in savedPasteboardData {
            item.setData(data, forType: type)
        }
        pasteboard.writeObjects([item])
        
        savedPasteboardData = []
        print("[TextInjector] Clipboard restored")
    }
    
    private func simulatePaste() {
        // Create event source
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            print("[TextInjector] Failed to create event source")
            return
        }
        
        // Virtual key code for 'V'
        let vKeyCode = CGKeyCode(kVK_ANSI_V)
        
        // Key down with Command modifier
        if let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true) {
            keyDown.flags = .maskCommand
            keyDown.post(tap: .cghidEventTap)
        }
        
        // Small delay between key down and up
        usleep(10000) // 10ms
        
        // Key up
        if let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false) {
            keyUp.flags = .maskCommand
            keyUp.post(tap: .cghidEventTap)
        }
        
        print("[TextInjector] Simulated Cmd+V paste")
    }
}
