import AudioToolbox
import Foundation

extension AudioObjectID {
  static let system = AudioObjectID(kAudioObjectSystemObject)
  static let unknown = kAudioObjectUnknown

  var isUnknown: Bool { self == .unknown }
  var isValid: Bool { !isUnknown }
}

extension AudioObjectID {
  static func readDefaultSystemOutputDevice() throws -> AudioDeviceID {
    try AudioDeviceID.system.readDefaultSystemOutputDevice()
  }

  static func readProcessList() throws -> [AudioObjectID] {
    try AudioObjectID.system.readProcessList()
  }

  static func translatePIDToProcessObjectID(pid: pid_t) throws -> AudioObjectID {
    try AudioDeviceID.system.translatePIDToProcessObjectID(pid: pid)
  }

  func readProcessList() throws -> [AudioObjectID] {
    try requireSystemObject()

    var address = AudioObjectPropertyAddress(
      mSelector: kAudioHardwarePropertyProcessObjectList,
      mScope: kAudioObjectPropertyScopeGlobal,
      mElement: kAudioObjectPropertyElementMain
    )

    var dataSize: UInt32 = 0
    var err = AudioObjectGetPropertyDataSize(self, &address, 0, nil, &dataSize)
    guard err == noErr else {
      throw AudioCaptureError.coreAudioError("Error reading data size for \(address): \(err)")
    }

    var value = [AudioObjectID](
      repeating: .unknown, count: Int(dataSize) / MemoryLayout<AudioObjectID>.size)
    err = AudioObjectGetPropertyData(self, &address, 0, nil, &dataSize, &value)
    guard err == noErr else {
      throw AudioCaptureError.coreAudioError("Error reading array for \(address): \(err)")
    }

    return value
  }

  func translatePIDToProcessObjectID(pid: pid_t) throws -> AudioObjectID {
    try requireSystemObject()

    let processObject = try read(
      kAudioHardwarePropertyTranslatePIDToProcessObject,
      defaultValue: AudioObjectID.unknown,
      qualifier: pid
    )

    guard processObject.isValid else {
      throw AudioCaptureError.invalidProcessID(pid)
    }

    return processObject
  }

  func readProcessBundleID() -> String? {
    if let result = try? readString(kAudioProcessPropertyBundleID) {
      result.isEmpty ? nil : result
    } else {
      nil
    }
  }

  func readProcessIsRunning() -> Bool {
    (try? readBool(kAudioProcessPropertyIsRunning)) ?? false
  }

  func readDefaultSystemOutputDevice() throws -> AudioDeviceID {
    try requireSystemObject()
    return try read(
      kAudioHardwarePropertyDefaultSystemOutputDevice, defaultValue: AudioDeviceID.unknown)
  }

  func readDeviceUID() throws -> String {
    try readString(kAudioDevicePropertyDeviceUID)
  }

  func readAudioTapStreamBasicDescription() throws -> AudioStreamBasicDescription {
    try read(kAudioTapPropertyFormat, defaultValue: AudioStreamBasicDescription())
  }

  private func requireSystemObject() throws {
    if self != .system {
      throw AudioCaptureError.invalidSystemObject
    }
  }
}

extension AudioObjectID {
  func read<T, Q>(
    _ selector: AudioObjectPropertySelector,
    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain,
    defaultValue: T,
    qualifier: Q
  ) throws -> T {
    try read(
      AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element),
      defaultValue: defaultValue,
      qualifier: qualifier
    )
  }

  func read<T>(
    _ selector: AudioObjectPropertySelector,
    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain,
    defaultValue: T
  ) throws -> T {
    try read(
      AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element),
      defaultValue: defaultValue
    )
  }

  func read<T, Q>(_ address: AudioObjectPropertyAddress, defaultValue: T, qualifier: Q) throws
    -> T {
    var inQualifier = qualifier
    let qualifierSize = UInt32(MemoryLayout<Q>.size(ofValue: qualifier))
    return try withUnsafeMutablePointer(to: &inQualifier) { qualifierPtr in
      try read(
        address,
        defaultValue: defaultValue,
        inQualifierSize: qualifierSize,
        inQualifierData: qualifierPtr
      )
    }
  }

  func read<T>(_ address: AudioObjectPropertyAddress, defaultValue: T) throws -> T {
    try read(
      address,
      defaultValue: defaultValue,
      inQualifierSize: 0,
      inQualifierData: nil
    )
  }

  func readString(
    _ selector: AudioObjectPropertySelector,
    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
  ) throws -> String {
    try read(
      AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element),
      defaultValue: "" as CFString) as String
  }

  func readBool(
    _ selector: AudioObjectPropertySelector,
    scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal,
    element: AudioObjectPropertyElement = kAudioObjectPropertyElementMain
  ) throws -> Bool {
    let value: Int = try read(
      AudioObjectPropertyAddress(mSelector: selector, mScope: scope, mElement: element),
      defaultValue: 0)
    return value == 1
  }

  private func read<T>(
    _ inAddress: AudioObjectPropertyAddress,
    defaultValue: T,
    inQualifierSize: UInt32 = 0,
    inQualifierData: UnsafeRawPointer? = nil
  ) throws -> T {
    var address = inAddress
    var dataSize: UInt32 = 0

    var err = AudioObjectGetPropertyDataSize(
      self, &address, inQualifierSize, inQualifierData, &dataSize)
    guard err == noErr else {
      throw AudioCaptureError.coreAudioError(
        "Error reading data size for \(inAddress): \(err)")
    }

    var value: T = defaultValue
    err = withUnsafeMutablePointer(to: &value) { ptr in
      AudioObjectGetPropertyData(
        self, &address, inQualifierSize, inQualifierData, &dataSize, ptr)
    }

    guard err == noErr else {
      throw AudioCaptureError.coreAudioError("Error reading data for \(inAddress): \(err)")
    }

    return value
  }
}

extension UInt32 {
  fileprivate var fourCharString: String {
    String(cString: [
      UInt8((self >> 24) & 0xFF),
      UInt8((self >> 16) & 0xFF),
      UInt8((self >> 8) & 0xFF),
      UInt8(self & 0xFF),
      0
    ])
  }
}

extension AudioObjectPropertyAddress {
  public var description: String {
    let elementDescription =
      mElement == kAudioObjectPropertyElementMain ? "main" : mElement.fourCharString
    return "\(mSelector.fourCharString)/\(mScope.fourCharString)/\(elementDescription)"
  }
}

enum AudioCaptureError: LocalizedError {
  case coreAudioError(String)
  case invalidProcessID(pid_t)
  case invalidSystemObject
  case tapCreationFailed(OSStatus)
  case deviceCreationFailed(OSStatus)
  case microphonePermissionDenied
  case unsupportedMacOSVersion

  var errorDescription: String? {
    switch self {
    case .coreAudioError(let message):
      return "Core Audio Error: \(message)"
    case .invalidProcessID(let pid):
      return "Invalid process identifier: \(pid)"
    case .invalidSystemObject:
      return "Only supported for the system object"
    case .tapCreationFailed(let status):
      return "Process tap creation failed with error \(status)"
    case .deviceCreationFailed(let status):
      return "Audio device creation failed with error \(status)"
    case .microphonePermissionDenied:
      return "Microphone permission denied"
    case .unsupportedMacOSVersion:
      return "Core Audio Taps requires macOS 14.2 or later"
    }
  }
}
