//
//  RecordingButton.swift
//  Recap
//
//  Created by Rawand Ahmad on 25/07/2025.
//

import Combine
import SwiftUI

struct RecordingButton: View {
  let isRecording: Bool
  let recordingDuration: TimeInterval
  let isEnabled: Bool
  let onToggleRecording: () -> Void

  init(
    isRecording: Bool,
    recordingDuration: TimeInterval,
    isEnabled: Bool = true,
    onToggleRecording: @escaping () -> Void
  ) {
    self.isRecording = isRecording
    self.recordingDuration = recordingDuration
    self.isEnabled = isEnabled
    self.onToggleRecording = onToggleRecording
  }

  private var formattedTime: String {
    let hours = Int(recordingDuration) / 3600
    let minutes = Int(recordingDuration) / 60 % 60
    let seconds = Int(recordingDuration) % 60
    return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
  }

  var body: some View {
    Button(action: isEnabled ? onToggleRecording : {}) {
      HStack(spacing: 6) {
        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(isEnabled ? .white : .gray)

        Text(isRecording ? "Recording \(formattedTime)" : "Start Recording")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(isEnabled ? .white : .gray)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(
        RoundedRectangle(cornerRadius: 20)
          .fill(Color(hex: "242323"))
          .overlay(
            RoundedRectangle(cornerRadius: 20)
              .stroke(
                LinearGradient(
                  gradient: Gradient(
                    stops: isRecording
                      ? [
                        .init(color: Color.red.opacity(0.4), location: 0),
                        .init(color: Color.red.opacity(0.2), location: 1)
                      ]
                      : [
                        .init(color: Color(hex: "979797").opacity(0.6), location: 0),
                        .init(color: Color(hex: "979797").opacity(0.4), location: 1)
                      ]),
                  startPoint: .top,
                  endPoint: .bottom
                ),
                lineWidth: 1
              )
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
    .animation(.easeInOut(duration: 0.3), value: isRecording)
  }
}

#Preview {
  RecordingButton(
    isRecording: false,
    recordingDuration: 0,
    onToggleRecording: {}
  )
  .padding()
  .background(Color.black)
}
