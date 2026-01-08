import Foundation
import WhisperKit

/// Wraps WhisperKit for on-device speech-to-text transcription
@MainActor
class SpeechRecognizer: ObservableObject {
    private var whisperKit: WhisperKit?
    
    @Published var isInitialized = false
    @Published var isInitializing = false
    @Published var initializationProgress: String = ""
    @Published var initializationError: String?
    
    /// Available Whisper model sizes
    enum ModelSize: String, CaseIterable {
        case tiny = "tiny.en"
        case base = "base.en"
        case small = "small.en"
        case medium = "medium.en"
        
        var displayName: String {
            switch self {
            case .tiny: return "Tiny (fastest, least accurate)"
            case .base: return "Base (balanced)"
            case .small: return "Small (better accuracy)"
            case .medium: return "Medium (best accuracy, slowest)"
            }
        }
    }
    
    enum SpeechRecognizerError: Error, LocalizedError {
        case notInitialized
        case alreadyInitializing
        case initializationFailed(underlying: Error)
        case transcriptionFailed(underlying: Error)
        case emptyResult
        
        var errorDescription: String? {
            switch self {
            case .notInitialized:
                return "Speech recognizer not initialized"
            case .alreadyInitializing:
                return "Speech recognizer is already initializing"
            case .initializationFailed(let error):
                return "Failed to initialize: \(error.localizedDescription)"
            case .transcriptionFailed(let error):
                return "Transcription failed: \(error.localizedDescription)"
            case .emptyResult:
                return "No speech detected"
            }
        }
    }
    
    /// Check if the recognizer is ready to transcribe
    var isReady: Bool {
        isInitialized && whisperKit != nil
    }
    
    /// Initialize WhisperKit with the specified model
    /// Downloads the model if not already cached
    func initialize(model: ModelSize = .base) async {
        guard !isInitialized else {
            print("[SpeechRecognizer] Already initialized")
            return
        }
        
        guard !isInitializing else {
            print("[SpeechRecognizer] Already initializing")
            return
        }
        
        isInitializing = true
        initializationProgress = "Preparing..."
        initializationError = nil
        print("[SpeechRecognizer] Initializing with model: \(model.rawValue)")
        
        // Retry up to 3 times
        var lastError: Error?
        for attempt in 1...3 {
            do {
                if attempt == 1 {
                    initializationProgress = "Downloading AI model..."
                } else {
                    initializationProgress = "Retrying download (attempt \(attempt)/3)..."
                }
                
                print("[SpeechRecognizer] Attempt \(attempt) - Loading model...")
                
                // WhisperKit will download the model if not cached
                whisperKit = try await WhisperKit(model: model.rawValue)
                
                isInitialized = true
                isInitializing = false
                initializationProgress = "Ready"
                print("[SpeechRecognizer] Initialization complete")
                return
                
            } catch {
                lastError = error
                print("[SpeechRecognizer] Attempt \(attempt) failed: \(error)")
                
                // Wait before retrying (exponential backoff)
                if attempt < 3 {
                    try? await Task.sleep(nanoseconds: UInt64(attempt * 2_000_000_000))
                }
            }
        }
        
        // All attempts failed
        isInitializing = false
        initializationProgress = ""
        
        // Provide user-friendly error message
        if let error = lastError {
            let errorString = error.localizedDescription.lowercased()
            if errorString.contains("network") || errorString.contains("internet") || errorString.contains("connection") || errorString.contains("offline") {
                initializationError = "No internet connection. Please connect to the internet to download the AI model (~150MB), then restart the app."
            } else if errorString.contains("disk") || errorString.contains("space") || errorString.contains("storage") {
                initializationError = "Not enough disk space. Please free up ~500MB and restart the app."
            } else {
                initializationError = "Failed to download AI model. Please check your internet connection and restart the app."
            }
        } else {
            initializationError = "Failed to initialize AI model. Please restart the app."
        }
        
        print("[SpeechRecognizer] Initialization failed after 3 attempts: \(initializationError ?? "Unknown")")
    }

    
    /// Transcribe audio from a file URL
    /// - Parameter audioURL: URL to the audio file (WAV format, 16kHz recommended)
    /// - Returns: Transcribed text
    func transcribe(audioURL: URL) async throws -> String {
        guard let whisperKit else {
            throw SpeechRecognizerError.notInitialized
        }
        
        print("[SpeechRecognizer] Transcribing: \(audioURL.lastPathComponent)")
        
        do {
            let results = try await whisperKit.transcribe(audioPath: audioURL.path)
            
            // Combine all segments into final text
            let text = results
                .compactMap { $0.text }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !text.isEmpty else {
                throw SpeechRecognizerError.emptyResult
            }
            
            print("[SpeechRecognizer] Transcription result: \(text)")
            return text
            
        } catch let error as SpeechRecognizerError {
            throw error
        } catch {
            throw SpeechRecognizerError.transcriptionFailed(underlying: error)
        }
    }
    
    /// Unload the model to free memory
    func unload() {
        whisperKit = nil
        isInitialized = false
        print("[SpeechRecognizer] Unloaded")
    }
}
