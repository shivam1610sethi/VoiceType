# VoiceType

A native macOS dictation app with a floating widget, Fn key activation, and on-device speech-to-text powered by WhisperKit.

![VoiceType Demo](docs/demo.gif)

## Features

- 🎙️ **Voice-to-Text Anywhere** - Dictate in any app where you can type
- ⌨️ **Fn Key Activation** - Press and hold Fn to start dictating
- 🔒 **100% Private** - All processing happens on-device using WhisperKit
- 💨 **Floating Widget** - Always visible, non-intrusive pill at the bottom of your screen
- 📋 **Clipboard Integration** - Copy your last transcription from the menu bar

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (M1, M2, M3, or later)
- ~500MB disk space for the Whisper model

## Installation

1. Download `VoiceType-1.0.0.dmg` from the [Releases](https://github.com/your-username/VoiceType/releases) page
2. Open the DMG and drag VoiceType to your Applications folder
3. Launch VoiceType from Applications
4. Grant the required permissions when prompted:
   - **Microphone**: To hear your voice
   - **Accessibility**: To detect the Fn key and insert text

## Usage

### Basic Dictation
1. Click on any text field where you want to type
2. Press and hold the **Fn** key
3. Speak clearly
4. Release the **Fn** key
5. Your text will be inserted automatically

### Hands-Free Mode
1. Click the floating widget to start recording
2. Speak your text
3. Click the red stop button when done

### Menu Bar
- Click the waveform icon in the menu bar for quick actions
- **Copy Last Transcription** - Copy your most recent dictation
- **Show/Hide Widget** - Toggle the floating widget visibility
- **Settings** - Configure VoiceType preferences

## Building from Source

### Prerequisites
- Xcode 15.0 or later
- macOS 14.0 or later

### Steps

```bash
# Clone the repository
git clone https://github.com/your-username/VoiceType.git
cd VoiceType

# Open in Xcode
open VoiceType.xcodeproj

# Build and run (Cmd+R)
```

### Distribution Build

1. **Build Archive**
   ```bash
   xcodebuild archive -scheme VoiceType -archivePath ./build/VoiceType.xcarchive
   ```

2. **Export App**
   ```bash
   xcodebuild -exportArchive -archivePath ./build/VoiceType.xcarchive \
     -exportPath ./build -exportOptionsPlist ExportOptions.plist
   ```

3. **Notarize** (requires Apple Developer account)
   ```bash
   chmod +x Scripts/notarize.sh
   ./Scripts/notarize.sh
   ```

4. **Create DMG**
   ```bash
   chmod +x Scripts/create-dmg.sh
   ./Scripts/create-dmg.sh
   ```

## Architecture

```
VoiceType/
├── App/
│   ├── VoiceTypeApp.swift      # SwiftUI app entry
│   ├── AppDelegate.swift       # Main coordinator
│   └── AppState.swift          # Observable state machine
├── Services/
│   ├── PermissionsManager.swift
│   ├── HotkeyMonitor.swift     # Global Fn key detection
│   ├── AudioRecorder.swift     # AVAudioEngine recording
│   ├── SpeechRecognizer.swift  # WhisperKit wrapper
│   └── TextInjector.swift      # Clipboard + paste simulation
├── Views/
│   ├── FloatingPanel.swift     # NSPanel subclass
│   ├── FloatingWidgetView.swift
│   ├── MenuBarController.swift
│   ├── OnboardingView.swift
│   └── SettingsView.swift
└── Scripts/
    ├── notarize.sh
    └── create-dmg.sh
```

## Privacy

VoiceType is designed with privacy in mind:

- **On-Device Processing**: All speech recognition happens locally using WhisperKit
- **No Data Collection**: We don't collect, store, or transmit any audio or transcriptions
- **No Internet Required**: Once the model is downloaded, VoiceType works completely offline

## Permissions

VoiceType requires the following permissions:

| Permission | Purpose |
|------------|---------|
| Microphone | To record your voice for transcription |
| Accessibility | To detect the Fn key globally and insert text at cursor |

## Troubleshooting

### "VoiceType is not responding to Fn key"
- Ensure Accessibility permission is granted in System Settings → Privacy & Security → Accessibility
- Try restarting VoiceType

### "Transcription is slow"
- The first transcription may be slow while the model loads
- Consider using the "Tiny" model in Settings for faster (but less accurate) results

### "Text is not being inserted"
- Ensure Accessibility permission is granted
- Click on a text field before dictating
- Some apps may block simulated keyboard input

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [WhisperKit](https://github.com/argmaxinc/WhisperKit) - On-device speech recognition
- [OpenAI Whisper](https://github.com/openai/whisper) - The underlying speech recognition model
