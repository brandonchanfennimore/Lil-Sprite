import SwiftUI

@main
struct macbookspriteApp: App {
    @StateObject private var model = PetWindowModel()
    private let controller: PetWindowController

    init() {
        let m = PetWindowModel()
        _model = StateObject(wrappedValue: m)

        let view = PetView()
            .environmentObject(m)

        let c = PetWindowController(model: m, rootView: view)
        c.showWindow(nil)
        controller = c
    }

    var body: some Scene {
        // No normal app window; just a tiny Settings scene so the app is valid.
        Settings {
            Text("Desktop Pet running…")
                .padding()
        }
    }
}
