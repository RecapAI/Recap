import SwiftUI

struct CustomDropdown<T: Hashable>: View {
  let title: String
  let options: [T]
  @Binding var selection: T
  let displayName: (T) -> String
  let showSearch: Bool

  @State private var isExpanded = false
  @State private var hoveredOption: T?
  @State private var searchText = ""

  private var filteredOptions: [T] {
    guard showSearch && !searchText.isEmpty else { return options }
    return options.filter { option in
      displayName(option).localizedCaseInsensitiveContains(searchText)
    }
  }

  init(
    title: String,
    options: [T],
    selection: Binding<T>,
    displayName: @escaping (T) -> String,
    showSearch: Bool = false
  ) {
    self.title = title
    self.options = options
    self._selection = selection
    self.displayName = displayName
    self.showSearch = showSearch
  }

  var body: some View {
    dropdownButton
      .popover(isPresented: $isExpanded, arrowEdge: .bottom) {
        dropdownList
          .frame(width: 285)
          .frame(maxHeight: showSearch ? 350 : 300)
      }
      .onChange(of: isExpanded) { _, expanded in
        if !expanded {
          searchText = ""
        }
      }
  }

  private var dropdownButton: some View {
    Button {
      isExpanded.toggle()
    } label: {
      HStack {
        Text(displayName(selection))
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(UIConstants.Colors.textPrimary)
          .lineLimit(1)

        Spacer()

        Image(systemName: "chevron.down")
          .font(.system(size: 10, weight: .medium))
          .foregroundColor(UIConstants.Colors.textSecondary)
          .rotationEffect(.degrees(isExpanded ? 180 : 0))
          .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isExpanded)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(hex: "2A2A2A").opacity(0.3))
          .overlay(
            RoundedRectangle(cornerRadius: 8)
              .stroke(
                LinearGradient(
                  gradient: Gradient(stops: [
                    .init(
                      color: Color(hex: "979797").opacity(0.2), location: 0),
                    .init(
                      color: Color(hex: "979797").opacity(0.1), location: 1)
                  ]),
                  startPoint: .top,
                  endPoint: .bottom
                ),
                lineWidth: 0.8
              )
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
  }

  private var searchField: some View {
    HStack {
      Image(systemName: "magnifyingglass")
        .font(.system(size: 10, weight: .medium))
        .foregroundColor(UIConstants.Colors.textSecondary)

      TextField("Search...", text: $searchText)
        .textFieldStyle(PlainTextFieldStyle())
        .font(.system(size: 11, weight: .medium))
        .foregroundColor(UIConstants.Colors.textPrimary)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 6)
    .background(
      RoundedRectangle(cornerRadius: 4)
        .fill(Color(hex: "2A2A2A").opacity(0.5))
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(Color(hex: "979797").opacity(0.2), lineWidth: 0.5)
        )
    )
  }

  private var dropdownList: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(hex: "1A1A1A"))
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .stroke(
              LinearGradient(
                gradient: Gradient(stops: [
                  .init(color: Color(hex: "979797").opacity(0.3), location: 0),
                  .init(color: Color(hex: "979797").opacity(0.2), location: 1)
                ]),
                startPoint: .top,
                endPoint: .bottom
              ),
              lineWidth: 0.8
            )
        )

      VStack(spacing: 0) {
        if showSearch {
          searchField
            .padding(.horizontal, 8)
            .padding(.top, 16)
        }

        ScrollView(.vertical, showsIndicators: true) {
          VStack(spacing: 0) {
            ForEach(filteredOptions, id: \.self) { option in
              Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                  selection = option
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                  isExpanded = false
                }
              } label: {
                HStack {
                  Text(displayName(option))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(
                      selection == option
                        ? UIConstants.Colors.textPrimary
                        : UIConstants.Colors.textSecondary
                    )
                    .lineLimit(1)

                  Spacer()

                  if selection == option {
                    Image(systemName: "checkmark")
                      .font(.system(size: 9, weight: .bold))
                      .foregroundColor(UIConstants.Colors.textPrimary)
                      .transition(.scale.combined(with: .opacity))
                  }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(
                  selection == option
                    ? Color.white.opacity(0.09)
                    : (hoveredOption == option
                      ? Color.white.opacity(0.01) : Color.clear)
                )
              }
              .buttonStyle(PlainButtonStyle())
              .onHover { isHovered in
                hoveredOption = isHovered ? option : nil
              }

              if option != filteredOptions.last {
                Divider()
                  .background(Color(hex: "979797").opacity(0.1))
              }
            }
          }
          .padding(.vertical, 8)
          .cornerRadius(8)
        }
      }

      // Gradient overlays
      VStack(spacing: 0) {
        // Top gradient
        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: Color(hex: "1A1A1A"), location: 0),
            .init(color: Color(hex: "1A1A1A").opacity(0.8), location: 0.3),
            .init(color: Color(hex: "1A1A1A").opacity(0), location: 1)
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 20)
        .allowsHitTesting(false)

        Spacer()

        // Bottom gradient
        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: Color(hex: "1A1A1A").opacity(0), location: 0),
            .init(color: Color(hex: "1A1A1A").opacity(0.8), location: 0.7),
            .init(color: Color(hex: "1A1A1A"), location: 1)
          ]),
          startPoint: .top,
          endPoint: .bottom
        )
        .frame(height: 20)
        .allowsHitTesting(false)
      }
      .cornerRadius(8)
    }
    .padding(8)
  }
}

#Preview {
  VStack(spacing: 40) {
    CustomDropdown(
      title: "Language",
      options: ["English", "Spanish", "French", "German"],
      selection: .constant("English"),
      displayName: { $0 }
    )
    .frame(width: 285)

    CustomDropdown(
      title: "Numbers",
      options: Array(1...20).map { "Option \($0)" },
      selection: .constant("Option 1"),
      displayName: { $0 },
      showSearch: true
    )
    .frame(width: 285)

    Text("This text should not move")
      .foregroundColor(.white)
  }
  .frame(width: 400, height: 500)
  .padding(40)
  .background(Color.black)
}
