import Foundation

/// An operation was called that a partial mock does not implement.
public enum MockAPIClientError: LocalizedError, Equatable, Sendable {

    case unimplementedOperation(operationID: String)

    public var errorDescription: String? {
        switch self {
        case .unimplementedOperation(let operationID):
            return "The mock does not implement the \(operationID) API operation."
        }
    }
}
