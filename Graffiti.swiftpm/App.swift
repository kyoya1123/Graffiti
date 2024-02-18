import SwiftUI

@main
@available(iOS 17.0, *)
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: .init())
        }
    }
}
