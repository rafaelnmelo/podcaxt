import Foundation
import os.log

extension URLSession {
    /// Performs a request with detailed debug logging for URL, headers, body, response and errors.
    func debugData(from url: URL) async throws -> (Data, URLResponse) {
        let request = URLRequest(url: url)
        return try await debugRequest(request)
    }

    /// Performs a URLRequest with detailed debug logging for URL, headers, body, response and errors.
    func debugRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let logger = Logger(subsystem: "com.podcaxt.network", category: "URLSession")
        
        logger.logRequest(request)

        do {
            let (data, response) = try await data(for: request)
            logger.logResponse(response, data: data)
            return (data, response)
        } catch {
            logger.logError(error)
            throw error
        }
    }
}

// MARK: - Logger Extension

private extension Logger {
    func logRequest(_ request: URLRequest) {
        #if !DEBUG
        return
        #endif
        self.debug("🌐 ===== 📤 Request Debug 📤 =====")
        self.debug("🟣 URL: \(request.url?.absoluteString ?? "nil")")
        self.debug("🟣 Method: \(request.httpMethod ?? "GET")")

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            self.debug("🟣 Headers: \(headers.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
        }

        if let body = request.httpBody {
            self.debug("🟣 Body:")
            logBody(body, contentType: request.value(forHTTPHeaderField: "Content-Type"))
        }
    }

    func logBody(_ body: Data, contentType: String?) {
        #if !DEBUG
        return
        #endif
        if let contentType,
           contentType.contains("multipart/form-data"),
           let boundary = contentType.components(separatedBy: "boundary=").last {
            logMultipartBody(body, boundary: boundary)
        } else if let string = String(data: body, encoding: .utf8) {
            self.debug("🔹 \(string.prefix(500))")
        } else {
            self.debug("🔹 [binary data: \(body.count) bytes]")
        }
    }

    func logMultipartBody(_ body: Data, boundary: String) {
        #if !DEBUG
        return
        #endif
        let parts = String(data: body, encoding: .ascii)?
            .components(separatedBy: "--\(boundary)")
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty } ?? []

        for part in parts {
            let components = part.components(separatedBy: "\r\n\r\n")
            guard components.count > 1 else { continue }

            let headers = components[0]
                .components(separatedBy: "\r\n")
                .filter { !$0.isEmpty }
                .map { "🔸 \($0)" }
                .joined(separator: "\n")

            let content = components[1...].joined(separator: "\r\n\r\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            self.debug("\(headers)")

            if components[0].contains("image/jpeg") || components[0].contains("application/octet-stream") {
                self.debug("🔹 [binary data omitted]")
            } else if !content.isEmpty {
                self.debug("🔹 Content: \(content.prefix(200))")
            }
        }
    }

    func logResponse(_ response: URLResponse, data: Data) {
        #if !DEBUG
        return
        #endif
        self.debug("🌐 ===== 📥 Response Debug 📥 =====")

        if let http = response as? HTTPURLResponse {
            self.debug("🟢 Status: \(http.statusCode)")
            if !http.allHeaderFields.isEmpty {
                self.debug("🟢 Headers: \(http.allHeaderFields.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
            }
        }

        self.debug("🟢 Data (\(data.count) bytes):")
        if let string = String(data: data, encoding: .utf8) {
            self.debug("🔹 \(string.prefix(500))")
        } else {
            self.debug("🔹 [binary data]")
        }
        self.debug("═══════════════════════════════════════")
    }

    func logError(_ error: Error) {
        #if !DEBUG
        return
        #endif
        self.debug("🌐 ===== ❌ Error Debug ❌ =====")
        self.debug("🔴 Error: \(error.localizedDescription)")
        self.debug("═══════════════════════════════════════")
    }
}
