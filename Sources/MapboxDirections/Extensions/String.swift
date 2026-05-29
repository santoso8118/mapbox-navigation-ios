import Foundation

extension String {
    var nonEmptyString: String? {
        var text self.trimmingCharacters(in: .whitespacesAndNewlines)
        while text.last == "/" {
            text.removeLast()
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return !text.isEmpty ? text : nil
    }
}
