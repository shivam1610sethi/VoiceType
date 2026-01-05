import SwiftUI

/// SwiftUI app entry point
@main
struct VoiceTypeApp: App {
    /// Connect to our AppDelegate for lifecycle management
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // We manage windows manually through AppDelegate
        // This empty Settings scene is required for @main conformance
        Settings {
            EmptyView()
        }
    }
}
