import Foundation

extension String {
    var strippingHTML: String {
        guard let data = data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html,
                          .characterEncoding: NSUTF8StringEncoding],
                documentAttributes: nil
              )
        else { return self }
        return attributed.string
    }
}
