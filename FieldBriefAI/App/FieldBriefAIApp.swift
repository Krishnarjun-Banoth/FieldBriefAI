import SwiftUI
import FirebaseCore
import FirebaseAppCheck

@main
struct FieldBriefAIApp: App {
    init() {
        if AppConfiguration.isFirebaseReady {
            #if DEBUG
            // Debug provider is NEVER shipped in Release builds.
            AppCheck.setAppCheckProviderFactory(AppCheckDebugProviderFactory())
            #else
            AppCheck.setAppCheckProviderFactory(AppAttestProviderFactory())
            #endif
            FirebaseApp.configure()
        }
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
