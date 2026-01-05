import Foundation

/// Extension helpers for the app
extension String {
    /// Truncate string to max length with ellipsis
    func truncated(to length: Int) -> String {
        if self.count <= length {
            return self
        }
        return String(self.prefix(length)) + "..."
    }
}

extension URL {
    /// Get temporary directory URL for audio recordings
    static var voiceTypeTemp: URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("VoiceType")
    }
}
