import SwiftUI
import Combine

/// Recording state machine
enum RecordingState: Equatable {
    case idle
    case recording
    case transcribing
    case error(String)
    
    static func == (lhs: RecordingState, rhs: RecordingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.recording, .recording): return true
        case (.transcribing, .transcribing): return true
        case (.error(let a), .error(let b)): return a == b
        default: return false
        }
    }
}

/// Central app state - observable by all views
@MainActor
class AppState: ObservableObject {
    // MARK: - Published State
    
    @Published var recordingState: RecordingState = .idle
    @Published var audioLevel: Float = 0
    @Published var lastTranscription: String?
    @Published var showOnboarding = false
    @Published var widgetVisible = true
    @Published var isInitialized = false
    
    // MARK: - Services
    
    let permissionsManager = PermissionsManager()
    let hotkeyMonitor = HotkeyMonitor()
    let audioRecorder = AudioRecorder()
    let speechRecognizer = SpeechRecognizer()
    let textInjector = TextInjector()
    
    // MARK: - Private
    
    private var recordingURL: URL?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
        // Start preloading model immediately
        startModelPreload()
    }
    
    private func setupBindings() {
        // Sync audio level from recorder to state
        audioRecorder.$audioLevel
            .receive(on: DispatchQueue.main)
            .assign(to: &$audioLevel)
        
        // Setup hotkey callbacks
        hotkeyMonitor.onFnKeyDown = { [weak self] in
            Task { @MainActor in
                self?.startRecording()
            }
        }
        
        hotkeyMonitor.onFnKeyUp = { [weak self] in
            Task { @MainActor in
                // Only stop if we're actually recording (not if user just tapped Fn)
                if self?.recordingState == .recording {
                    self?.stopRecording()
                }
            }
        }
    }
    
    /// Start preloading the WhisperKit model in the background
    func startModelPreload() {
        Task {
            print("[AppState] Starting model preload...")
            await speechRecognizer.initialize(model: .base)
        }
    }
    
    /// Initialize services (call after permissions granted)
    func initializeServices() async {
        guard !isInitialized else { return }
        
        print("[AppState] Initializing services...")
        
        // Wait for model to finish loading if still in progress
        if !speechRecognizer.isReady && !speechRecognizer.isInitializing {
            await speechRecognizer.initialize(model: .base)
        }
        
        // Start hotkey monitoring
        hotkeyMonitor.startMonitoring()
        print("[AppState] Hotkey monitoring started")
        
        isInitialized = true
    }
    
    // MARK: - Recording Control
    
    /// Start recording from microphone
    func startRecording() {
        guard recordingState == .idle else {
            print("[AppState] Cannot start recording - not idle")
            return
        }
        
        // Check permissions
        guard permissionsManager.microphoneStatus == .granted else {
            recordingState = .error("Microphone access required")
            return
        }
        
        // Check if model is ready
        // Check if model is ready
        guard speechRecognizer.isReady else {
            if speechRecognizer.isInitializing {
                recordingState = .error("Model still loading... \(speechRecognizer.initializationProgress)")
            } else if let error = speechRecognizer.initializationError {
                recordingState = .error("Model error. Check app window.")
                // Automatically open onboarding/app window if there's an error
                DispatchQueue.main.async {
                    self.showOnboarding = true
                    // Activate app to bring window to front
                    NSApp.activate(ignoringOtherApps: true)
                    // NotificationCenter default used in AppDelegate to show window
                    NotificationCenter.default.post(name: NSNotification.Name("ShowOnboarding"), object: nil)
                }
            } else {
                recordingState = .error("Initializing model...")
                Task {
                    await speechRecognizer.initialize()
                }
            }
            return
        }
        
        do {
            recordingURL = try audioRecorder.startRecording()
            recordingState = .recording
            print("[AppState] Recording started")
        } catch {
            print("[AppState] Failed to start recording: \(error)")
            recordingState = .error("Failed to start recording")
        }
    }
    
    /// Stop recording and begin transcription
    func stopRecording() {
        guard recordingState == .recording else { return }
        
        guard let url = audioRecorder.stopRecording() else {
            print("[AppState] No recording URL")
            recordingState = .idle
            return
        }
        
        print("[AppState] Recording stopped, starting transcription...")
        recordingState = .transcribing
        
        Task {
            await transcribeAndInject(audioURL: url)
        }
    }
    
    /// Cancel recording without transcribing
    func cancelRecording() {
        guard recordingState == .recording else { return }
        
        if let url = audioRecorder.stopRecording() {
            try? FileManager.default.removeItem(at: url)
        }
        
        recordingState = .idle
        print("[AppState] Recording cancelled")
    }
    
    /// Dismiss error state
    func dismissError() {
        if case .error = recordingState {
            recordingState = .idle
        }
    }
    
    // MARK: - Transcription
    
    private func transcribeAndInject(audioURL: URL) async {
        do {
            // Transcribe
            let text = try await speechRecognizer.transcribe(audioURL: audioURL)
            
            // Store transcription
            lastTranscription = text
            
            // Inject text at cursor
            textInjector.injectText(text)
            
            // Return to idle
            recordingState = .idle
            
            print("[AppState] Transcription complete and injected: \(text.prefix(50))...")
            
        } catch {
            print("[AppState] Transcription failed: \(error)")
            recordingState = .error("Transcription failed")
        }
        
        // Clean up temp file
        try? FileManager.default.removeItem(at: audioURL)
    }
    
    // MARK: - Clipboard
    
    /// Copy last transcription to clipboard
    func copyLastTranscription() {
        guard let text = lastTranscription else { return }
        textInjector.copyToClipboard(text)
        print("[AppState] Copied to clipboard: \(text.prefix(50))...")
    }
    
    // MARK: - Cleanup
    
    func shutdown() {
        hotkeyMonitor.stopMonitoring()
        if recordingState == .recording {
            _ = audioRecorder.stopRecording()
        }
    }
}
