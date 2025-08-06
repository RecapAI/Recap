import Foundation
import SwiftUI

struct TranscriptDropdownButton: View {
    let transcriptText: String
    
    @State private var isCollapsed: Bool = true
    
    init(transcriptText: String) {
        self.transcriptText = transcriptText
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                    .font(.system(size: 16, weight: .bold))
    
                
            VStack(alignment: .leading) {
                Text("Transcript")
                    .font(UIConstants.Typography.cardTitle)
                    .foregroundColor(UIConstants.Colors.textPrimary)
                
                VStack {
                    
                    if (!isCollapsed) {
                        Text(transcriptText)
                    }
                }
            }

            Spacer()
        
        }
        .frame(alignment: .topLeading)
        .padding(.horizontal, UIConstants.Spacing.cardPadding + 4)
        .padding(.vertical, UIConstants.Spacing.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "242323"))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(stops: [
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
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.25)) {
                isCollapsed.toggle()
            }
        }
    }
}

#Preview {
    GeometryReader { geometry in
        VStack(spacing: 16) {
            TranscriptDropdownButton(
                transcriptText: "Lorem ipsum dolor sit amet"
            )
        }
        .padding(20)
    }
    .frame(width: 500, height: 300)
    .background(UIConstants.Gradients.backgroundGradient)
}
