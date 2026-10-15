import Foundation

public enum AdvancedSettingsLockError: LocalizedError, Equatable {
    case incorrectCode
    case unlockCodeNotSet

    public var errorDescription: String? {
        switch self {
        case .incorrectCode:
            return String(localized: "Incorrect code. Try again.", bundle: .module)
        case .unlockCodeNotSet:
            return String(localized: "The advanced settings could not be changed. Try again.", bundle: .module)
        }
    }
}
