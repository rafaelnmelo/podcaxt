import Foundation

extension TimeInterval {
    /// Returns a formatted duration string in `mm:ss` or `hh:mm:ss` format.
    var formattedDuration: String? {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = self >= 3600 ? [.hour, .minute, .second] : [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter.string(from: self)
    }
}
