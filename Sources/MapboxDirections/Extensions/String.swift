import Foundation

extension String {
    var nonEmptyString: String? {
        var text = self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        while text.last == "/" {
            text.removeLast()
            text = text.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        }
        return !text.isEmpty ? text : nil
    }
}
