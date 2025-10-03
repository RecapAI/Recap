import AppKit

@MainActor
protocol StatusBarDelegate: AnyObject {
    func statusItemClicked()
    func quitRequested()
}

final class StatusBarManager: StatusBarManagerType {
    private var statusItem: NSStatusItem?
    weak var delegate: StatusBarDelegate?
    private var themeObserver: NSObjectProtocol?
    private var isRecording = false

    init() {
        setupStatusItem()
        setupThemeObserver()
    }

    var statusButton: NSStatusBarButton? {
        statusItem?.button
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            updateIconForCurrentTheme()
            button.target = self
            button.action = #selector(handleButtonClick(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupThemeObserver() {
        themeObserver = nil
    }

    private func updateIconForCurrentTheme() {
        guard let button = statusItem?.button else { return }

        print("🎨 updateIconForCurrentTheme called, isRecording: \(isRecording)")

        // Always use the black icon, regardless of theme
        if let image = NSImage(named: "barIcon-dark") {
            if isRecording {
                // Create red-tinted version
                let tintedImage = createTintedImage(from: image, tint: .systemRed)
                button.image = tintedImage
                button.contentTintColor = nil
                print("🎨 Applied red tinted image")
            } else {
                // Use original image
                let workingImage = image.copy() as! NSImage
                workingImage.isTemplate = true
                button.image = workingImage
                button.contentTintColor = nil
                print("🎨 Applied normal image")
            }
        } else if let fallback = NSImage(named: "barIcon") {
            if isRecording {
                // Create red-tinted version
                let tintedImage = createTintedImage(from: fallback, tint: .systemRed)
                button.image = tintedImage
                button.contentTintColor = nil
                print("🎨 Applied red tinted fallback image")
            } else {
                // Use original image
                let workingImage = fallback.copy() as! NSImage
                workingImage.isTemplate = true
                button.image = workingImage
                button.contentTintColor = nil
                print("🎨 Applied normal fallback image")
            }
        }
    }

    private func createTintedImage(from originalImage: NSImage, tint: NSColor) -> NSImage {
        let size = originalImage.size
        let tintedImage = NSImage(size: size)

        tintedImage.lockFocus()

        // Draw the original image
        originalImage.draw(in: NSRect(origin: .zero, size: size))

        // Apply the tint color with multiply blend mode
        tint.set()
        NSRect(origin: .zero, size: size).fill(using: .sourceAtop)

        tintedImage.unlockFocus()

        return tintedImage
    }

    func setRecordingState(_ recording: Bool) {
        print("🎯 StatusBarManager.setRecordingState called with: \(recording)")
        isRecording = recording
        updateIconForCurrentTheme()
        print("🎯 Icon updated, isRecording = \(isRecording)")
    }

    @objc private func handleButtonClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            showContextMenu()
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.delegate?.statusItemClicked()
            }
        }
    }

    private func showContextMenu() {
        let contextMenu = NSMenu()

        let quitItem = NSMenuItem(title: "Quit Recap", action: #selector(quitMenuItemClicked), keyEquivalent: "q")
        quitItem.target = self

        contextMenu.addItem(quitItem)

        if let button = statusItem?.button {
            contextMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.maxY), in: button)
        }
    }

    @objc private func quitMenuItemClicked() {
        DispatchQueue.main.async { [weak self] in
            self?.delegate?.quitRequested()
        }
    }

    deinit {
        if let observer = themeObserver {
            DistributedNotificationCenter.default.removeObserver(observer)
        }
        statusItem = nil
    }
}
