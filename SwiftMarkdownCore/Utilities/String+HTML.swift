import Foundation

extension String {
    /// Returns the string with HTML special characters escaped.
    ///
    /// Escapes: `&` `<` `>` `"`
    var htmlEscaped: String {
        self
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
