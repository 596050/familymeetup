import SwiftUI

struct TestingAppState: Decodable {
    var onboarding: OnboardingState?
    var profiles: [FamilyProfile]?
}

struct OnboardingState: Decodable {
    var hasOnboarded: Bool
    var names: String
    var city: String
    var kids: String
    var interests: String
}

struct FamilyProfile: Decodable {
    var name: String
    var city: String
    var kids: String
    var color: String
}

enum AppStateLoader {
    static func loadState(named name: String = "state") -> TestingAppState? {
        let override = ProcessInfo.processInfo.environment["FM_STATE_NAME"]
        let name = override ?? name
        let bundle = Bundle.main
        // Try with subdirectory (if Xcode preserved structure), then fallback to root
        let candidates: [URL?] = [
            bundle.url(forResource: name, withExtension: "json", subdirectory: "AppState"),
            bundle.url(forResource: name, withExtension: "json")
        ]
        guard let url = candidates.compactMap({ $0 }).first else { return nil }
        do {
            let data = try Data(contentsOf: url)
            let state = try JSONDecoder().decode(TestingAppState.self, from: data)
            return state
        } catch {
            print("Failed to load \(name).json: \(error)")
            return nil
        }
    }

    static func color(from name: String) -> Color {
        switch name.lowercased() {
        case "pink": return .pink
        case "orange": return .orange
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "teal": return .teal
        case "indigo": return .indigo
        case "red": return .red
        case "brown": return .brown
        case "mint": return .mint
        default: return .gray
        }
    }
}
