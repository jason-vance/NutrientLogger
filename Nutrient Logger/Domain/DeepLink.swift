import Foundation

enum DeepLink: Equatable {
    case dashboard
    case search
    case profile
    case premium

    init?(url: URL) {
        guard url.scheme == "nutrientlogger" else { return nil }

        switch url.host {
        case "dashboard":
            self = .dashboard
        case "search", "log":
            self = .search
        case "profile", "goals":
            self = .profile
        case "premium", "subscribe":
            self = .premium
        default:
            return nil
        }
    }

    var tab: AppTab {
        switch self {
        case .dashboard, .premium:
            return .dashboard
        case .search:
            return .search
        case .profile:
            return .profile
        }
    }
}

enum AppTab: Hashable {
    case dashboard
    case search
    case body
    case profile
}
