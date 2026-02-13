import AVFoundation
import AudioToolbox
import OSLog
import SwiftUI

final class SystemWideTap: ObservableObject, AudioTapType {
  typealias InvalidationHandler = (SystemWideTap) -> Void

  let muteWhenRunning: Bool
  private let logger: Logger

  private(set) var errorMessage: String?
  @Published private(set) var audioLevel: Float = 0.0

  fileprivate func setAudioLevel(_ level: Float) {
    audioLevel = level
  }

  init(muteWhenRunning: Bool = false) {
    self.muteWhenRunning = muteWhenRunning
    self.logger = Logger(
      subsystem: AppConstants.Logging.subsystem,
      category:
        "\(String(describing: SystemWideTap.self))")
  }

  @ObservationIgnored
  private var processTapID: AudioObjectID = .unknown
  @ObservationIgnored
  private var aggregateDeviceID = AudioObjectID.unknown
  @ObservationIgnored
  private var deviceProcID: AudioDeviceIOProcID?
  @ObservationIgnored
  private(set) var tapStreamDescription: AudioStreamBasicDescription?
  @ObservationIgnored
  private var invalidationHandler: InvalidationHandler?

  @ObservationIgnored
  private(set) var activated = false

  @MainActor
  func activate() {
    guard !activated else { return }
    activated = true

    logger.debug(#function)

    self.errorMessage = nil

    do {
      try prepareSystemWideTap()
    } catch {
      logger.error("\(error, privacy: .public)")
      self.errorMessage = error.localizedDescription
    }
  }

  func invalidate() {
    guard activated else { return }
    defer { activated = false }

    logger.debug(#function)

    invalidationHandler?(self)
    self.invalidationHandler = nil

    if aggregateDeviceID.isValid {
      var err = AudioDeviceStop(aggregateDeviceID, deviceProcID)
      if err != noErr {
        logger.warning("Failed to stop aggregate device: \(err, privacy: .public)")
      }

      if let deviceProcID = deviceProcID {
        err = AudioDeviceDestroyIOProcID(aggregateDeviceID, deviceProcID)
        if err != noErr {
          logger.warning("Failed to destroy device I/O proc: \(err, privacy: .public)")
        }
        self.deviceProcID = nil
      }

      err = AudioHardwareDestroyAggregateDevice(aggregateDeviceID)
      if err != noErr {
        logger.warning("Failed to destroy aggregate device: \(err, privacy: .public)")
      }
      aggregateDeviceID = .unknown
    }

    if processTapID.isValid {
      let err = AudioHardwareDestroyProcessTap(processTapID)
      if err != noErr {
        logger.warning("Failed to destroy audio tap: \(err, privacy: .public)")
      }
      self.processTapID = .unknown
    }
  }

  private func prepareSystemWideTap() throws {
    errorMessage = nil

    let tapDescription = CATapDescription(stereoGlobalTapButExcludeProcesses: [])
    tapDescription.uuid = UUID()
    tapDescription.muteBehavior = muteWhenRunning ? .mutedWhenTapped : .unmuted
    tapDescription.name = "SystemWideAudioTap"
    tapDescription.isPrivate = true
    tapDescription.isExclusive = true

    var tapID: AUAudioObjectID = .unknown
    var err = AudioHardwareCreateProcessTap(tapDescription, &tapID)

    guard err == noErr else {
      errorMessage = "System-wide process tap creation failed with error \(err)"
      return
    }

    logger.debug("Created system-wide process tap #\(tapID, privacy: .public)")

    self.processTapID = tapID

    let systemOutputID = try AudioDeviceID.readDefaultSystemOutputDevice()
    let outputUID = try systemOutputID.readDeviceUID()
    let aggregateUID = UUID().uuidString

    let description: [String: Any] = [
      kAudioAggregateDeviceNameKey: "SystemWide-Tap",
      kAudioAggregateDeviceUIDKey: aggregateUID,
      kAudioAggregateDeviceMainSubDeviceKey: outputUID,
      kAudioAggregateDeviceIsPrivateKey: true,
      kAudioAggregateDeviceIsStackedKey: false,
      kAudioAggregateDeviceTapAutoStartKey: true,
      kAudioAggregateDeviceSubDeviceListKey: [
        [
          kAudioSubDeviceUIDKey: outputUID
        ]
      ],
      kAudioAggregateDeviceTapListKey: [
        [
          kAudioSubTapDriftCompensationKey: true,
          kAudioSubTapUIDKey: tapDescription.uuid.uuidString
        ]
      ]
    ]

    self.tapStreamDescription = try tapID.readAudioTapStreamBasicDescription()

    aggregateDeviceID = AudioObjectID.unknown
    err = AudioHardwareCreateAggregateDevice(description as CFDictionary, &aggregateDeviceID)
    guard err == noErr else {
      throw "Failed to create aggregate device: \(err)"
    }

    logger.debug(
      "Created system-wide aggregate device #\(self.aggregateDeviceID, privacy: .public)")
  }

  func run(
    on queue: DispatchQueue, ioBlock: @escaping AudioDeviceIOBlock,
    invalidationHandler: @escaping InvalidationHandler
  ) throws {
    assert(activated, "\(#function) called with inactive tap!")
    assert(self.invalidationHandler == nil, "\(#function) called with tap already active!")

    errorMessage = nil

    logger.debug("Run system-wide tap!")

    self.invalidationHandler = invalidationHandler

    var err = AudioDeviceCreateIOProcIDWithBlock(&deviceProcID, aggregateDeviceID, queue, ioBlock)
    guard err == noErr else { throw "Failed to create device I/O proc: \(err)" }

    err = AudioDeviceStart(aggregateDeviceID, deviceProcID)
    guard err == noErr else { throw "Failed to start audio device: \(err)" }
  }

  deinit {
    invalidate()
  }
}

final class SystemWideTapRecorder: ObservableObject, AudioTapRecorderType {
  let fileURL: URL
  private let queue = DispatchQueue(label: "SystemWideTapRecorder", qos: .userInitiated)
  private let logger: Logger

  @ObservationIgnored
  private weak var _tap: SystemWideTap?

  private(set) var isRecording = false

  init(fileURL: URL, tap: SystemWideTap) {
    self.fileURL = fileURL
    self._tap = tap
    self.logger = Logger(
      subsystem: AppConstants.Logging.subsystem,
      category: "\(String(describing: SystemWideTapRecorder.self))(\(fileURL.lastPathComponent))"
    )
  }

  private var tap: SystemWideTap {
    get throws {
      guard let tap = _tap else {
        throw AudioCaptureError.coreAudioError("System-wide tap unavailable")
      }
      return tap
    }
  }

  @ObservationIgnored
  private var currentFile: AVAudioFile?

  @MainActor
  func start() throws {
    logger.debug(#function)

    guard !isRecording else {
      logger.warning("\(#function, privacy: .public) while already recording")
      return
    }

    let tap = try tap

    if !tap.activated {
      tap.activate()
    }

    guard var streamDescription = tap.tapStreamDescription else {
      throw AudioCaptureError.coreAudioError("Tap stream description not available")
    }

    guard let format = AVAudioFormat(streamDescription: &streamDescription) else {
      throw AudioCaptureError.coreAudioError("Failed to create AVAudioFormat")
    }

    logger.info("Using system-wide audio format: \(format, privacy: .public)")

    let settings: [String: Any] = [
      AVFormatIDKey: streamDescription.mFormatID,
      AVSampleRateKey: format.sampleRate,
      AVNumberOfChannelsKey: format.channelCount
    ]

    let file = try AVAudioFile(
      forWriting: fileURL, settings: settings, commonFormat: .pcmFormatFloat32,
      interleaved: format.isInterleaved)

    self.currentFile = file

    try tap.run(on: queue) { [weak self] _, inInputData, _, _, _ in
      guard let self, let currentFile = self.currentFile else { return }
      do {
        guard
          let buffer = AVAudioPCMBuffer(
            pcmFormat: format, bufferListNoCopy: inInputData,
            deallocator: nil)
        else {
          throw "Failed to create PCM buffer"
        }

        try currentFile.write(from: buffer)

        self.updateAudioLevel(from: buffer)
      } catch {
        logger.error("\(error, privacy: .public)")
      }
    } invalidationHandler: { [weak self] _ in
      guard let self else { return }
      handleInvalidation()
    }

    isRecording = true
  }

  func stop() {
    do {
      logger.debug(#function)

      guard isRecording else { return }

      currentFile = nil
      isRecording = false

      try tap.invalidate()
    } catch {
      logger.error("Stop failed: \(error, privacy: .public)")
    }
  }

  private func handleInvalidation() {
    guard isRecording else { return }
    logger.debug(#function)
  }

  private func updateAudioLevel(from buffer: AVAudioPCMBuffer) {
    guard let floatData = buffer.floatChannelData else { return }

    let channelCount = Int(buffer.format.channelCount)
    let frameLength = Int(buffer.frameLength)

    var maxLevel: Float = 0.0

    for channel in 0..<channelCount {
      let channelData = floatData[channel]

      var channelLevel: Float = 0.0
      for frame in 0..<frameLength {
        let sample = abs(channelData[frame])
        channelLevel = max(channelLevel, sample)
      }

      maxLevel = max(maxLevel, channelLevel)
    }

    let decibels = 20 * log10(max(maxLevel, 0.00001))
    let normalizedLevel = (decibels + 60) / 60

    Task { @MainActor in
      self._tap?.setAudioLevel(min(max(normalizedLevel, 0), 1))
    }
  }
}
