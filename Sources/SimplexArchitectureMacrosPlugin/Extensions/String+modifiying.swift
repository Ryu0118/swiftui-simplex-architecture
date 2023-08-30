import Foundation

extension String {
    func modifying(_ transform: (Self) throws -> Self) rethrows -> String {
        try transform(self)
    }
}
