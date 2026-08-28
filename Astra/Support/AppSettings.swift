import Foundation

/// The UserDefaults keys, in one place so a typo in a string literal cannot
/// silently split a setting in two. Views read them with @AppStorage directly.
enum AppSettings {
    enum Key {
        static let lastSelectedRover = "lastSelectedRover"
        static let lastSelectedYear = "lastSelectedYear"
        static let gridColumnCount = "gridColumnCount"
        static let hasSeenOnboarding = "hasSeenOnboarding"
    }

    static let defaultYear = 2012
    static let columnCountRange = 2...3
}
