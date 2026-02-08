import AVFoundation
import OSLog

extension MicrophoneCapture {
    
    func performBackgroundPreparation() async {
        logger.debug("Starting background preparation")
        
        do {
            try prepareAudioEngine()
            
            await MainActor.run {
                self.isPreWarmed = true
            }
            
            logger.info("Background preparation completed")
        } catch {
            logger.error("Background preparation failed: \(error)")
        }
    }
    
    func prepareAudioEngine() throws {
        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        
        let inputFormat = inputNode.inputFormat(forBus: 0)
        self.inputFormat = inputFormat
        self.inputNode = inputNode
        
        logger.info("Hardware input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount)ch, format: \(inputFormat)")
        
        let mixerNode = AVAudioMixerNode()
        engine.attach(mixerNode)
        self.converterNode = mixerNode
        
        engine.connect(inputNode, to: mixerNode, format: inputFormat)
        
        let mixerOutputFormat = inputFormat
        logger.info("Mixer output format set to match input: \(mixerOutputFormat.sampleRate)Hz, \(mixerOutputFormat.channelCount)ch")
        
        if let targetFormat = targetFormat {
            logger.info("Target format requested: \(targetFormat.sampleRate)Hz, \(targetFormat.channelCount)ch")
            logger.info("Format conversion will be applied during buffer processing")
        }
        
        self.audioEngine = engine
        
        logger.info("AVAudioEngine prepared successfully with consistent format chain")
    }
    
    func startAudioEngine() throws {
        guard let audioEngine = audioEngine else {
            throw AudioCaptureError.coreAudioError("AudioEngine not prepared")
        }
        
        guard let outputURL = outputURL else {
            throw AudioCaptureError.coreAudioError("No output URL specified")
        }
        
        // Verify input node is available and has audio input
        guard let inputNode = inputNode else {
            throw AudioCaptureError.coreAudioError("Input node not available")
        }
        
        let inputFormat = inputNode.inputFormat(forBus: 0)
        logger.info("Starting audio engine with input format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount)ch")
        
        // Check if input node has audio input available
        if inputFormat.channelCount == 0 {
            logger.warning("Input node has no audio channels available - microphone may not be connected or permission denied")
            throw AudioCaptureError.coreAudioError("No audio input channels available - check microphone connection and permissions")
        }
        
        // Verify microphone permission before starting
        let permissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if permissionStatus != .authorized {
            logger.error("Microphone permission not authorized: \(permissionStatus.rawValue)")
            throw AudioCaptureError.microphonePermissionDenied
        }
        
        try createAudioFile(at: outputURL)
        try installAudioTap()
        
        do {
            try audioEngine.start()
            logger.info("AVAudioEngine started successfully")
        } catch {
            logger.error("Failed to start AVAudioEngine: \(error)")
            throw AudioCaptureError.coreAudioError("Failed to start audio engine: \(error.localizedDescription)")
        }
        
        isRecording = true
    }
    
    func installAudioTap() throws {
        guard let converterNode = converterNode else {
            throw AudioCaptureError.coreAudioError("Converter node not available")
        }
        
        guard let inputFormat = inputFormat else {
            throw AudioCaptureError.coreAudioError("Input format not available")
        }
        
        let tapFormat = inputFormat
        
        converterNode.installTap(onBus: 0, bufferSize: 1024, format: tapFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer, at: time)
        }
        
        logger.info("Audio tap installed with input format: \(tapFormat.sampleRate)Hz, \(tapFormat.channelCount)ch")
        logger.info("Format consistency ensured: Hardware -> Mixer -> Tap all use same format")
    }
    
    func createAudioFile(at url: URL) throws {
        let outputFormat = targetFormat ?? inputFormat
        guard let finalFormat = outputFormat else {
            throw AudioCaptureError.coreAudioError("No valid output format")
        }
        
        let file = try AVAudioFile(
            forWriting: url,
            settings: finalFormat.settings,
            commonFormat: .pcmFormatFloat32,
            interleaved: finalFormat.isInterleaved
        )
        
        self.audioFile = file
        
        if let targetFormat = targetFormat {
            logger.info("AVAudioFile created with target format: \(targetFormat.sampleRate)Hz, \(targetFormat.channelCount)ch")
        } else {
            logger.info("AVAudioFile created with input format: \(finalFormat.sampleRate)Hz, \(finalFormat.channelCount)ch")
        }
    }
    
    func stopAudioEngine() {
        guard let audioEngine = audioEngine, isRecording else { return }
        
        converterNode?.removeTap(onBus: 0)
        audioEngine.stop()
        
        isRecording = false
        audioLevel = 0.0
    }
    
    func closeAudioFile() {
        audioFile = nil
    }
}
