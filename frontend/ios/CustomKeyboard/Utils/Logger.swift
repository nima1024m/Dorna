import Foundation

/// Centralized logging utility that gates output behind DEBUG.
/// Replace direct `Logger.debug` calls with these helpers to avoid
/// sprinkling `#if DEBUG` across the codebase.
public enum Logger {
    /// Logs a simple message only in debug builds.
    public static func debug(_ message: @autoclosure () -> String) {
        #if DEBUG
        NSLog("%@", message())
        #endif
    }

    /// Logs a formatted message only in debug builds.
    public static func debug(_ format: String, _ args: CVarArg...) {
        #if DEBUG
        let formatted = String(format: format, arguments: args)
        NSLog("%@", formatted)
        #endif
    }

    /// Logs large text in chunks to avoid allocating huge strings in one go.
    /// Useful for debugging full document contents.
    public static func debugFullText(_ text: String, chunkSize: Int = 800, label: String? = nil) {
        #if DEBUG
        var start = text.startIndex
        while start < text.endIndex {
            let end = text.index(start, offsetBy: chunkSize, limitedBy: text.endIndex) ?? text.endIndex
            let chunk = String(text[start..<end])
            if let label = label {
                NSLog("%@: %@", label, chunk)
            } else {
                NSLog("%@", chunk)
            }
            start = end
        }
        #endif
    }
}