import SwiftUI

struct DownloadPillButton: View {
    let text: String
    let isDownloading: Bool
    let downloadProgress: Double
    let action: () -> Void
    
    @State private var iconOffset: CGFloat = 0
    
    var body: some View {
        Button(action: isDownloading ? {} : action) {
            HStack(spacing: 4) {
                Image(systemName: isDownloading ? "arrow.down" : "square.and.arrow.down")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
                    .offset(y: isDownloading ? iconOffset : 0)
                    .animation(isDownloading ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default, value: iconOffset)
                
                Text(text)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "242323"))
                    
                    if isDownloading && downloadProgress > 0 {
                        GeometryReader { geometry in
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(width: geometry.size.width * min(max(downloadProgress, 0), 1))
                                .animation(.easeInOut(duration: 0.3), value: downloadProgress)
                        }
                        .mask(RoundedRectangle(cornerRadius: 16))
                    }
                    
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: Color(hex: "979797"), location: 0),
                                    .init(color: Color(hex: "979797").opacity(0.8), location: 1)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .clipped()
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDownloading)
        .onAppear {
            if isDownloading {
                iconOffset = 3
            }
        }
        .onChange(of: isDownloading) { oldValue, newValue in
            if newValue {
                iconOffset = 3
            } else {
                iconOffset = 0
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        DownloadPillButton(
            text: "Download",
            isDownloading: false,
            downloadProgress: 0.0
        ) {
            print("Download started")
        }
        
        DownloadPillButton(
            text: "Downloading",
            isDownloading: true,
            downloadProgress: 0.3
        ) {
            print("Download in progress")
        }
        
        DownloadPillButton(
            text: "Downloading",
            isDownloading: true,
            downloadProgress: 0.7
        ) {
            print("Download in progress")
        }
        
        DownloadPillButton(
            text: "Downloaded",
            isDownloading: false,
            downloadProgress: 1.0
        ) {
            print("Download complete")
        }
    }
    .padding()
    .background(Color.black)
}