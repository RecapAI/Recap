import SwiftUI

struct CustomTextEditor: View {
    let title: String
    let textBinding: Binding<String>
    let placeholder: String
    let height: CGFloat
    
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    init(
        title: String,
        text: Binding<String>,
        placeholder: String = "",
        height: CGFloat = 100
    ) {
        self.title = title
        self.textBinding = text
        self.placeholder = placeholder
        self.height = height
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(UIConstants.Colors.textSecondary)
            
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(hex: "2A2A2A").opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(stops: [
                                        .init(color: Color(hex: "979797").opacity(isFocused ? 0.4 : 0.2), location: 0),
                                        .init(color: Color(hex: "979797").opacity(isFocused ? 0.3 : 0.1), location: 1)
                                    ]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: 0.8
                            )
                    )
                    .frame(height: height)
                
                if textBinding.wrappedValue.isEmpty && !isFocused {
                    Text(placeholder)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(UIConstants.Colors.textSecondary.opacity(0.6))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .allowsHitTesting(false)
                }
                
                TextEditor(text: textBinding)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(UIConstants.Colors.textPrimary)
                    .background(Color.clear)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .focused($isFocused)
                    .lineLimit(nil)
                    .textSelection(.enabled)
                    .onChange(of: isFocused) { oldValue, focused in
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isEditing = focused
                        }
                    }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextEditor(
            title: "Custom Prompt",
            text: .constant(""),
            placeholder: "Enter your custom prompt template here...",
            height: 120
        )
        
        CustomTextEditor(
            title: "With Content",
            text: .constant(UserPreferencesInfo.defaultPromptTemplate),
            placeholder: "Enter text...",
            height: 80
        )
    }
    .frame(width: 400, height: 300)
    .padding(20)
    .background(Color.black)
}
