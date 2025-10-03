import AVFoundation
import OSLog

extension MicrophoneCapture {
    
    func processAudioBuffer(_ buffer: AVAudioPCMBuffer, at time: AVAudioTime) {
        guard isRecording else { return }
        
        // Log audio data reception for debugging
        if buffer.frameLength > 0 {
            logger.debug("Microphone received audio data: \(buffer.frameLength) frames, \(buffer.format.sampleRate)Hz, \(buffer.format.channelCount)ch")
        }
        
        calculateAndUpdateAudioLevel(from: buffer)
        
        if let audioFile = audioFile {
            do {
                if let targetFormat = targetFormat,
                   buffer.format.sampleRate != targetFormat.sampleRate ||
                   buffer.format.channelCount != targetFormat.channelCount {
                    
                    if let convertedBuffer = convertBuffer(buffer, to: targetFormat) {
                        try audioFile.write(from: convertedBuffer)
                        logger.debug("Wrote converted audio buffer: \(convertedBuffer.frameLength) frames")
                    } else {
                        logger.warning("Failed to convert buffer, writing original")
                        try audioFile.write(from: buffer)
                    }
                } else {
                    try audioFile.write(from: buffer)
                    logger.debug("Wrote audio buffer: \(buffer.frameLength) frames")
                }
            } catch {
                logger.error("Failed to write audio buffer: \(error)")
            }
        } else {
            logger.warning("No audio file available for writing")
        }
    }
    
    func convertBuffer(_ inputBuffer: AVAudioPCMBuffer, to targetFormat: AVAudioFormat) -> AVAudioPCMBuffer? {
        guard let converter = AVAudioConverter(from: inputBuffer.format, to: targetFormat) else {
            return nil
        }
        
        let frameCapacity = AVAudioFrameCount(Double(inputBuffer.frameLength) * (targetFormat.sampleRate / inputBuffer.format.sampleRate))
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: frameCapacity) else {
            return nil
        }
        
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return inputBuffer
        }
        
        if status == .error {
            logger.error("Audio conversion failed: \(error?.localizedDescription ?? "Unknown error")")
            return nil
        }
        
        return outputBuffer
    }

    func calculateAndUpdateAudioLevel(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return }
        
        var sum: Float = 0
        for i in 0..<frameCount {
            sum += abs(channelData[i])
        }
        
        let average = sum / Float(frameCount)
        let level = min(average * 10, 1.0)
        
        DispatchQueue.main.async { [weak self] in
            self?.audioLevel = level
        }
    }
    
    func checkStatus(_ status: OSStatus, _ operation: String) throws {
        guard status == noErr else {
            throw AudioCaptureError.coreAudioError("\(operation) failed: \(status)")
        }
    }
}
