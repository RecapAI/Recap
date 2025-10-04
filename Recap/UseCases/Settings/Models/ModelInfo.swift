//
//  ModelInfo.swift
//  Recap
//
//  Created by Rawand Ahmad on 27/07/2025.
//

import Foundation

struct ModelInfo {
  let displayName: String
  let parameters: String
  let vram: String
  let relativeSpeed: String

  var helpText: String {
    return """
      \(displayName)
      Size: \(parameters) parameters
      Required VRAM: \(vram)
      Relative Speed: \(relativeSpeed)
      """
  }
}

extension String {
  static let modelInfoData: [String: ModelInfo] = [
    "tiny": ModelInfo(
      displayName: "Tiny Model",
      parameters: "39M",
      vram: "~1 GB",
      relativeSpeed: "~10x"
    ),
    "base": ModelInfo(
      displayName: "Base Model",
      parameters: "74M",
      vram: "~1 GB",
      relativeSpeed: "~7x"
    ),
    "small": ModelInfo(
      displayName: "Small Model",
      parameters: "244M",
      vram: "~2 GB",
      relativeSpeed: "~4x"
    ),
    "medium": ModelInfo(
      displayName: "Medium Model",
      parameters: "769M",
      vram: "~5 GB",
      relativeSpeed: "~2x"
    ),
    "large": ModelInfo(
      displayName: "Large Model",
      parameters: "1550M",
      vram: "~10 GB",
      relativeSpeed: "1x (baseline)"
    ),
    "distil-whisper_distil-large-v3_turbo": ModelInfo(
      displayName: "Turbo Model",
      parameters: "809M",
      vram: "~6 GB",
      relativeSpeed: "~8x"
    )
  ]
}
