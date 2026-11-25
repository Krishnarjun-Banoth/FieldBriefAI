import Foundation

enum AppConfiguration {
    // Never hardcode API keys or App Check debug tokens. Bundled Firebase config is
    // added by the developer from the Firebase console and excluded from git.
    static var isFirebaseReady: Bool {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }
}
