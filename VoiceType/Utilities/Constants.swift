import Foundation

/// App-wide constants
enum Constants {
    /// App bundle identifier
    static let bundleIdentifier = "com.voicetype.app"
    
    /// Default Whisper model
    static let defaultWhisperModel = "base.en"
    
    /// Recording settings
    enum Recording {
        /// Sample rate for audio recording (16kHz for Whisper)
        static let sampleRate: Double = 16000
        
        /// Number of audio channels (mono)
        static let channels: Int = 1
    }
    
    /// UI
    enum UI {
        /// Floating widget offset from bottom of screen
        static let widgetBottomOffset: CGFloat = 50
        
        /// Animation duration for state transitions
        static let stateTransitionDuration: Double = 0.3
    }
    
    /// User defaults keys
    enum UserDefaults {
        static let launchAtLogin = "launchAtLogin"
        static let showWidgetOnStartup = "showWidgetOnStartup"
        static let playSoundOnComplete = "playSoundOnComplete"
        static let whisperModel = "whisperModel"
        static let autoCapitalize = "autoCapitalize"
        static let autoPunctuation = "autoPunctuation"
    }
}
