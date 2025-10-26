import SwiftUI

#if DEBUG
    import Foundation
#endif

@main
struct FamilyMeetApp: App {
    init() {
        #if DEBUG
            let env = ProcessInfo.processInfo.environment
            if env["FM_RESET_DEFAULTS"] == "1" {
                UserDefaults.standard.removeObject(forKey: "fm_profile")
                UserDefaults.standard.removeObject(forKey: "fm_hasOnboarded")
            }
            // Pre-seed UserDefaults with testing state as early as possible
            if let state = AppStateLoader.loadState(named: env["FM_STATE_NAME"] ?? "state") {
                if let ob = state.onboarding {
                    // Only seed if not already set to avoid clobbering user changes
                    if UserDefaults.standard.string(forKey: "fm_profile")?.isEmpty ?? true {
                        let dict: [String: String] = [
                            "names": ob.names,
                            "city": ob.city,
                            "kids": ob.kids,
                            "interests": ob.interests,
                        ]
                        if let data = try? JSONSerialization.data(
                            withJSONObject: dict, options: []),
                            let json = String(data: data, encoding: .utf8)
                        {
                            UserDefaults.standard.set(json, forKey: "fm_profile")
                        }
                    }
                    // Seed hasOnboarded flag
                    if UserDefaults.standard.object(forKey: "fm_hasOnboarded") == nil {
                        UserDefaults.standard.set(ob.hasOnboarded, forKey: "fm_hasOnboarded")
                    }
                }
            }
        #endif
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
