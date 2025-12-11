<img width="900" height="846" alt="github_export" src="https://github.com/user-attachments/assets/df798940-820c-46b6-b149-3a2771c7b5f3" />


## Screenshots
<details>
  <summary>View Screenshots</summary>

  ### Recap Preview
  <img width="1139" height="565" alt="image" src="https://github.com/user-attachments/assets/65b41806-c86f-4c16-ab0f-4114da5dfd8c" />

  ### Previous Recaps
  <img width="923" height="538" alt="image" src="https://github.com/user-attachments/assets/3b810b4f-a8b4-4755-bfd7-8ef1d3a3c953" />

  ### General Settings
  <img width="1038" height="524" alt="image" src="https://github.com/user-attachments/assets/5cfdf0d7-6c89-4f2e-9bae-8bfd6e14ca6d" />

  ### Whisper Models Section
  <img width="1051" height="546" alt="image" src="https://github.com/user-attachments/assets/a3a3249b-b94d-492d-8009-3ad661cff45f" />

</details>

## Jump to:

- [Why Recap?](#why-recap)
- [Features](#features)
- [System Requirements](#system-requirements)
- [How It Works](#how-it-works)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)

## Why Recap?

Ever been in a meeting where you wanted to focus on your work but still catch the important bits? That's exactly why I created Recap.

I found myself constantly torn between paying attention to meetings and getting actual work done. Sometimes I'd miss crucial decisions while coding, or I'd lose my flow state trying to take notes. I needed something that could listen for me and give me the highlights afterward.

But here's the thing - I didn't want my private conversations floating around on some company's servers. When you're discussing sensitive business matters, product roadmaps, or personal topics, that data should stay on YOUR machine. That's why Recap processes everything locally on your Mac using Apple's own technologies.

Recap is broken in its current state, but since I use it daily myself, you can absolutely expect new features soon!

---

> [!TIP]
> Recap is in an incomplete state and I suggest that it is not used for production and daily usage, but help in shaping it is greatly appreciated.

# Recap

Recap is an open-source, privacy-focused, macOS-native project to help you summarize your meetings. You could summarize audio of any app, not just meetings.

## Features
- **Meeting Detection**: Automatically detects meetings in Microsoft Teams, Zoom, Google Meet, and more using macOS ScreenCaptureKit
- **Audio Recording**: Records system audio and optionally microphone input
- **Local Processing**: Uses WhisperKit for transcription and Ollama/(optionally, OpenRouter) for summarization
- **Privacy First**: No data leaves your device unless you choose to share it
- **Open Source**: Fully transparent codebase for community contributions


#### Under the hood
-  Native Core Audio taps, AVAudioEngine, driver-free system audio capture  
-  WhisperKit (MLX) (local transcription), Ollama/OpenRouter (summarization)  
-  Swift + SwiftUI

### Roadmap:

Working on the following features now:
- [ ] Meeting Detection (Teams, Zoom, Google etc)
- [ ] Custom Prompt Via Settings (PR In Progress)
- [ ] Live Transcription using Parakeet V2 (PR In Progress)
- [ ] Background Audio Processing
- [ ] Auto Recording Stop
- [ ] Better Error Handling
- [ ] 85% or more test coverage

Right now, Recap is more of a POC of what I am trying to make. It records system audio (Core Audio Taps) + with an optional microphone recording (your audio) and feeds it to Whisper for transcription and then uses Ollama for summarizing.

**LLM Options:**
- **Ollama** (recommended): Complete privacy - everything stays on your device
- **OpenRouter**: Cloud-based option if you lack local compute capacity, but data leaves your device

## System Requirements

<details>
  <summary>Ollama (Local Processing)</summary>

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **macOS** | 15.0 or later | 15.0 or later |
| **Processor** | Apple M1  | Apple M2 Pro or newer |
| **RAM** | 16 GB | 32 GB or more |
| **Storage** | 10 GB free space | 50 GB free space |

</details>

<details>
    <summary>OpenRouter (Cloud Processing)</summary>

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| **macOS** | 15.0 or later | 15.0 or later |
| **Processor** | Apple M1 | Apple M2 or newer |
| **RAM** | 8 GB | 16 GB or more |
| **Storage** | 2 GB free space | 5 GB free space |

</details>


> **Note**: Intel Macs are not supported. Use it at your own risk.

## How It Works

```text
                              ┌───────────────┐
                          ┌───┤ 1. App Start  │
                          │   └───────────────┘
                          ▼
                    ┌─────────────┐
                    │2.App Select │
                    └─────────────┘
                          │
                          ▼
               ┌────────────────────────┐
               │3. Start Recording      │
               │   • System Audio       │
               │   • Microphone (opt)   │
               └────────────────────────┘
                          │
                          ▼
               ┌────────────────────────┐
               │4. Stop Recording       │
               │   • Save Audio Files   │
               │   • Create DB Record   │
               └────────────────────────┘
                          │
                          ▼
               ┌────────────────────────┐
               │5. Background Process   │
               │   • Transcribe Audio   │
               │   • Generate Summary   │
               └────────────────────────┘
                          │
                          ▼
               ┌────────────────────────┐
               │6. Complete & Store     │
               │   • Update DB Record   │
               │   • Show Results       │
               └────────────────────────┘
````

## Installation

Currently, Recap is only available through compilation from source. Pre-built releases will be available once core features are stabilized.

### Compile from Source

1. **Prerequisites:**

   * Ensure your system meets the [requirements](#system-requirements) above
   * Install Xcode 15.0 or later from the Mac App Store

2. **Clone and Build:**

   ```bash
   git clone https://github.com/rawandahmad698/recap.git
   cd recap
   open Recap.xcodeproj
   ```

3. **Build in Xcode:**

   * Build and run (⌘+R)

> **Note**: Distribution via Mac App Store and direct download will be available in future releases once the app reaches production readiness.

## Usage

### Required Environment Variables (Set Via Xcode Scheme Editor)

- Support for Keychain-based token storage soon
  
Before using, you need to set up the following environment variables using Xcode Scheme Editor:

* **`HF_TOKEN`** (Required): Hugging Face token for downloading Whisper models

  ```bash
  HF_TOKEN="your_huggingface_token_here"
  ```

Read [Hugging Face documentation](https://huggingface.co/docs/hub/security-tokens) to get a token!

* **`OPENROUTER_API_KEY`** (Optional): Only required if using OpenRouter for summarization

  ```bash
  OPENROUTER_API_KEY="your_openrouter_api_key_here"
  ```

Read [OpenRouter documentation](https://openrouter.ai/docs/api-keys) to get a key!

### First-Time Setup

#### Ollama Setup
1. Download Ollama here: [Ollama](https://ollama.com/download)
2. Pull the latest models (i.e. Llama 3):

   ```bash
   ollama pull llama3
   ```

#### Whisper Models

1. **Download & Select a Model:**

   * Open Recap and go to **Settings → Whisper Models**
   * Download a Whisper model (recommended: **Large v3** for best accuracy)
   * Wait for the download to complete before proceeding

2. **Configure LLM Provider:**

   * Go to **Settings → LLM Models**
   * Choose your preferred provider (Ollama or OpenRouter)
   * If using Ollama, ensure it's installed and running locally

3. **Start Recording:**

   * Select an audio application from the dropdown
   * Click the record button to start capturing
   * Optionally enable microphone for dual-audio recording
   * Click stop when finished - processing will begin automatically


## Contributing

I really need help finishing Recap! Any contribution is greatly welcomed.

**Focus:**

* See [Roadmap](#roadmap) above for current focus areas

### How to Contribute

1. **Fork the repository** and create a feature branch
2. **Submit a pull request** with clear description of changes

All skill levels welcome - from fixing typos to architecting new features. I really mean it!

#### Linter
Not using any linter right now, but I am planning to use SwiftLint/SwiftFormat in the future (PRs greatly welcomed).


####  Be notified of releases, watch the repo!
![Watch releases](https://github.com/user-attachments/assets/21a9caad-b27d-4fe9-859b-7de27d6b4084)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=rawandahmad698/Recap&type=Date)](https://www.star-history.com/#rawandahmad698/Recap&Date)

## License

MIT License

Copyright © 2025 Rawand Ahmed Shaswar

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
What this means:

 Any kind of usage allowed — personal, educational, or commercial use and modification is permitted.
 Redistribution allowed — you may freely redistribute the original or modified project.

Please see the LICENSE file for full details.

