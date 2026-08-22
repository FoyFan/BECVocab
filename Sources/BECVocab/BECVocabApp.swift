import SwiftUI

@main
struct BECVocabApp: App {
    @State private var dataService = DataService()
    @State private var speechService = SpeechService()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(dataService)
                .environment(speechService)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1100, height: 720)
    }
}