import SwiftUI
import AppKit

@MainActor
final class DropdownWindowManager: ObservableObject {
    private var dropdownWindow: NSWindow?
    private let dropdownWidth: CGFloat = 280
    private let maxDropdownHeight: CGFloat = 400
    
    func showDropdown(
        relativeTo button: NSView,
        viewModel: AppSelectionViewModel,
        onAppSelected: @escaping (SelectableApp) -> Void,
        onClearSelection: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        hideDropdown()
        
        let contentView = AppSelectionDropdown(
            viewModel: viewModel,
            onAppSelected: { app in
                onAppSelected(app)
                self.hideDropdown()
            },
            onClearSelection: {
                onClearSelection()
                self.hideDropdown()
            }
        )
        
        let actualHeight = calculateDropdownHeight(
            meetingApps: viewModel.meetingApps,
            otherApps: viewModel.otherApps
        )
        
        let hostingController = NSHostingController(rootView: contentView)
        hostingController.view.wantsLayer = true
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: dropdownWidth, height: actualHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        hostingController.view.frame = NSRect(x: 0, y: 0, width: dropdownWidth, height: actualHeight)
        
        window.contentViewController = hostingController
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = true
        window.level = .floating
        window.isReleasedWhenClosed = false
        
        positionDropdown(window: window, relativeTo: button)
        
        window.orderFront(nil)
        dropdownWindow = window
        
        animateDropdownIn(window: window)
        setupOutsideClickDetection(onDismiss: onDismiss)
    }
    
    func hideDropdown() {
        guard let window = dropdownWindow else { return }
        
        animateDropdownOut(window: window) {
            Task { @MainActor in
                window.orderOut(nil)
                self.dropdownWindow = nil
            }
        }
        
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
            globalMonitor = nil
        }
    }
    
    private var globalMonitor: Any?
    
    private func animateDropdownIn(window: NSWindow) {
        window.alphaValue = 0
        window.setFrame(
            window.frame.offsetBy(dx: -20, dy: 0),
            display: false
        )
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().alphaValue = 1
            window.animator().setFrame(
                window.frame.offsetBy(dx: 20, dy: 0),
                display: true
            )
        }
    }
    
    private func animateDropdownOut(window: NSWindow, completion: @Sendable @escaping () -> Void) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            window.animator().setFrame(
                window.frame.offsetBy(dx: -15, dy: 0),
                display: true
            )
        }, completionHandler: completion)
    }
    
    private func setupOutsideClickDetection(onDismiss: @escaping () -> Void) {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            onDismiss()
            self.hideDropdown()
        }
    }
    
    private func positionDropdown(window: NSWindow, relativeTo button: NSView) {
        guard let buttonWindow = button.window else { return }
        
        let buttonFrame = button.convert(button.bounds, to: nil)
        let buttonScreenFrame = buttonWindow.convertToScreen(buttonFrame)
        
        let spacing: CGFloat = 50
        let dropdownX = buttonScreenFrame.minX - dropdownWidth - spacing
        let dropdownY = buttonScreenFrame.minY
        
        window.setFrameOrigin(NSPoint(x: dropdownX, y: dropdownY))
    }
    
    private func calculateDropdownHeight(
        meetingApps: [SelectableApp],
        otherApps: [SelectableApp]
    ) -> CGFloat {
        let rowHeight: CGFloat = 32
        let sectionHeaderHeight: CGFloat = 28
        let dividerHeight: CGFloat = 17
        let clearSelectionRowHeight: CGFloat = 32
        let verticalPadding: CGFloat = 24
        
        var totalHeight = verticalPadding
        
        if !meetingApps.isEmpty {
            totalHeight += sectionHeaderHeight
            totalHeight += CGFloat(meetingApps.count) * rowHeight
            
            if !otherApps.isEmpty {
                totalHeight += dividerHeight
            }
        }
        
        if !otherApps.isEmpty {
            totalHeight += sectionHeaderHeight
            totalHeight += CGFloat(otherApps.count) * rowHeight
        }
        
        if !meetingApps.isEmpty || !otherApps.isEmpty {
            totalHeight += dividerHeight
            totalHeight += clearSelectionRowHeight
        }
        
        return min(totalHeight, maxDropdownHeight)
    }
}
