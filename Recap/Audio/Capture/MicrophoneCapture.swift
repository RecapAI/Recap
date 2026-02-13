//
//  MicrophoneCapture.swift
//  Recap
//
//  Created by Rawand Ahmad on 01/08/2025.
//

import AVFoundation
import AudioToolbox
import AudioUnit
import Combine
import OSLog

final class MicrophoneCapture: MicrophoneCaptureType {
  let logger = Logger(
    subsystem: AppConstants.Logging.subsystem,
    category: String(describing: MicrophoneCapture.self))

  var audioEngine: AVAudioEngine?
  var audioFile: AVAudioFile?
  var isRecording = false
  var outputURL: URL?

  var inputNode: AVAudioInputNode?
  var converterNode: AVAudioMixerNode?

  var targetFormat: AVAudioFormat?
  var inputFormat: AVAudioFormat?

  var preparationTask: Task<Void, Never>?
  var isPreWarmed = false

  @Published var audioLevel: Float = 0.0

  init() {
    startBackgroundPreparation()
  }

  deinit {
    cleanup()
  }

  func start(outputURL: URL, targetFormat: AudioStreamBasicDescription? = nil) throws {
    self.outputURL = outputURL

    if let targetDesc = targetFormat {
      var format = targetDesc
      self.targetFormat = AVAudioFormat(streamDescription: &format)

      logger.info(
        """
        Target format set from ProcessTap: \(targetDesc.mSampleRate)Hz, \
        \(targetDesc.mChannelsPerFrame)ch, formatID: \(String(format: "0x%08x", targetDesc.mFormatID))
        """)
    }

    waitForPreWarmIfNeeded()

    try startAudioEngine()
    logger.info("MicrophoneCapture started with AVAudioEngine")
  }

  func stop() {
    guard isRecording else { return }
    stopAudioEngine()
    closeAudioFile()
    logger.info("MicrophoneCapture stopped")
  }

  var recordingFormat: AVAudioFormat? {
    return targetFormat ?? inputFormat
  }

}

extension MicrophoneCapture {

  func startBackgroundPreparation() {
    preparationTask = Task {
      await performBackgroundPreparation()
    }
  }

  private func waitForPreWarmIfNeeded() {
    guard preparationTask != nil else { return }

    let startTime = CFAbsoluteTimeGetCurrent()
    while !isPreWarmed && (CFAbsoluteTimeGetCurrent() - startTime) < 0.1 {
      usleep(1000)
    }
  }

  func cleanup() {
    preparationTask?.cancel()

    if isRecording {
      stop()
    }

    if let audioEngine = audioEngine {
      audioEngine.stop()
      converterNode?.removeTap(onBus: 0)
    }

    closeAudioFile()
  }

}
