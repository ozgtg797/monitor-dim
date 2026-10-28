import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private var statusItem: NSStatusItem!
    private var launchAtLoginItem: NSMenuItem?
    private let slider = NSSlider(value: 100, minValue: 0, maxValue: 100, target: nil, action: nil)
    private let valueLabel = NSTextField(labelWithString: "–")

    // Everything touching the display runs on this queue; DDC calls block for tens of ms.
    private let queue = DispatchQueue(label: "monitor-dim.ddc")
    private var display: DDCDisplay?
    private var maxValue = 100

    // Latest slider value not yet sent; dragging only ever sends the newest one.
    private let lock = NSLock()
    private var pending: Int?
    private var draining = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.button?.image = NSImage(systemSymbolName: "sun.max", accessibilityDescription: "Monitor brightness")

        let menu = NSMenu()
        menu.delegate = self
        let sliderItem = NSMenuItem()
        sliderItem.view = makeSliderView()
        menu.addItem(sliderItem)
        menu.addItem(.separator())
        let loginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)
        launchAtLoginItem = loginItem
        menu.addItem(NSMenuItem(title: "Quit MonitorDim", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.queue.async { self?.display = nil }
        }

        refresh()
    }

    func menuWillOpen(_ menu: NSMenu) {
        launchAtLoginItem?.state = SMAppService.mainApp.status == .enabled ? .on : .off
        refresh()
    }

    @objc private func toggleLaunchAtLogin() {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            let alert = NSAlert()
            alert.messageText = "Couldn't change Launch at Login"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func makeSliderView() -> NSView {
        let title = NSTextField(labelWithString: "Display")
        title.font = .boldSystemFont(ofSize: NSFont.systemFontSize)

        valueLabel.font = .monospacedDigitSystemFont(ofSize: NSFont.smallSystemFontSize, weight: .regular)
        valueLabel.textColor = .secondaryLabelColor
        valueLabel.alignment = .right

        let header = NSStackView(views: [title, NSView(), valueLabel])

        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(sliderMoved)

        let low = NSImageView(image: NSImage(systemSymbolName: "sun.min", accessibilityDescription: nil)!)
        let high = NSImageView(image: NSImage(systemSymbolName: "sun.max", accessibilityDescription: nil)!)
        [low, high].forEach { $0.contentTintColor = .secondaryLabelColor }
        let row = NSStackView(views: [low, slider, high])

        let stack = NSStackView(views: [header, row])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6
        stack.edgeInsets = NSEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
        [header, row].forEach { $0.widthAnchor.constraint(equalTo: stack.widthAnchor, constant: -28).isActive = true }

        stack.frame = NSRect(x: 0, y: 0, width: 260, height: 58)
        return stack
    }

    @objc private func sliderMoved() {
        let percent = Int(slider.doubleValue.rounded())
        valueLabel.stringValue = "\(percent)%"

        lock.lock()
        pending = percent
        let start = !draining
        draining = true
        lock.unlock()

        if start { queue.async { self.drain() } }
    }

    private func drain() {
        while true {
            lock.lock()
            guard let percent = pending else {
                draining = false
                lock.unlock()
                return
            }
            pending = nil
            lock.unlock()

            guard let display = connectedDisplay() else { continue }
            let value = percent * maxValue / 100
            if !display.write(DDCDisplay.brightness, value) {
                self.display = nil
                connectedDisplay()?.write(DDCDisplay.brightness, value)
            }
        }
    }

    /// Re-reads the monitor so the slider follows changes made with its own buttons.
    private func refresh() {
        queue.async {
            let reading = self.connectedDisplay()?.read(DDCDisplay.brightness)
            DispatchQueue.main.async {
                guard let reading else {
                    self.slider.isEnabled = false
                    self.valueLabel.stringValue = "No display"
                    return
                }
                self.slider.isEnabled = true
                self.lock.lock()
                let busy = self.draining
                self.lock.unlock()
                guard !busy else { return }
                let percent = reading.max > 0 ? reading.current * 100 / reading.max : 0
                self.slider.doubleValue = Double(percent)
                self.valueLabel.stringValue = "\(percent)%"
            }
        }
    }

    /// Must be called on `queue`.
    private func connectedDisplay() -> DDCDisplay? {
        if let display { return display }
        for candidate in DDCDisplay.externalDisplays() {
            if let reading = candidate.read(DDCDisplay.brightness) {
                display = candidate
                maxValue = max(reading.max, 1)
                return candidate
            }
        }
        return nil
    }
}
