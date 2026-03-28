import Foundation

extension URLSession {
    /// Performs a request with detailed debug logging for URL, headers, body, response and errors.
    func debugData(from url: URL) async throws -> (Data, URLResponse) {
        let request = URLRequest(url: url)
        return try await debugRequest(request)
    }

    /// Performs a URLRequest with detailed debug logging for URL, headers, body, response and errors.
    func debugRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        #if DEBUG
        logRequest(request)
        #endif

        do {
            let (data, response) = try await data(for: request)

            #if DEBUG
            logResponse(response, data: data)
            #endif

            return (data, response)
        } catch {
            #if DEBUG
            logError(error)
            #endif
            throw error
        }
    }
}

// MARK: - Private Logging

#if DEBUG
private extension URLSession {
    func logRequest(_ request: URLRequest) {
        print("\n🌐 ===== 📤 Request Debug 📤 =====")
        print("🟣 URL: \(request.url?.absoluteString ?? "nil")")
        print("🟣 Method: \(request.httpMethod ?? "GET")")

        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            print("🟣 Headers: \(headers.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
        }

        if let body = request.httpBody {
            print("🟣 Body:")
            logBody(body, contentType: request.value(forHTTPHeaderField: "Content-Type"))
        }
    }

    func logBody(_ body: Data, contentType: String?) {
        if let contentType,
           contentType.contains("multipart/form-data"),
           let boundary = contentType.components(separatedBy: "boundary=").last {
            logMultipartBody(body, boundary: boundary)
        } else if let string = String(data: body, encoding: .utf8) {
            print("🔹 \(string.prefix(500))")
        } else {
            print("🔹 [binary data: \(body.count) bytes]")
        }
    }

    func logMultipartBody(_ body: Data, boundary: String) {
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

            print(headers)

            if components[0].contains("image/jpeg") || components[0].contains("application/octet-stream") {
                print("🔹 [binary data omitted]")
            } else if !content.isEmpty {
                print("🔹 Content: \(content.prefix(200))")
            }
        }
    }

    func logResponse(_ response: URLResponse, data: Data) {
        print("\n🌐 ===== 📥 Response Debug 📥 =====")

        if let http = response as? HTTPURLResponse {
            print("🟢 Status: \(http.statusCode)")
            if !http.allHeaderFields.isEmpty {
                print("🟢 Headers: \(http.allHeaderFields.map { "\($0.key): \($0.value)" }.joined(separator: ", "))")
            }
        }

        print("🟢 Data (\(data.count) bytes):")
        if let string = String(data: data, encoding: .utf8) {
            print("🔹 \(string.prefix(500))")
        } else {
            print("🔹 [binary data]")
        }
        print("═══════════════════════════════════════")
    }

    func logError(_ error: Error) {
        print("\n🌐 ===== ❌ Error Debug ❌ =====")
        print("🔴 Error: \(error.localizedDescription)")
        print("═══════════════════════════════════════")
    }
}
#endif
