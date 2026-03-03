import SwiftUI
import AppKit
import Combine

// Holds a weak reference to the window so SwiftUI can move it later.
final class PetWindowModel: ObservableObject {
    let objectWillChange = ObservableObjectPublisher()
    weak var window: NSWindow?
}


final class PetWindowController: NSWindowController {
    let model: PetWindowModel

    init(model: PetWindowModel, rootView: some View) {
        self.model = model

        let hosting = NSHostingView(rootView: rootView)
        hosting.wantsLayer = true
        hosting.layer?.backgroundColor = NSColor.clear.cgColor

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 10, width: 1475, height: 925),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )


        window.isOpaque = false
        window.backgroundColor = .black
        window.hasShadow = false

        // Keep the pet above normal windows
        window.level = .floating

        // Show on all Spaces + over fullscreen apps
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary
        ]

        // Click-through so it doesn't block your apps
        window.ignoresMouseEvents = true

        window.contentView = hosting

        // Store reference for movement control from SwiftUI
        model.window = window

        super.init(window: window)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
