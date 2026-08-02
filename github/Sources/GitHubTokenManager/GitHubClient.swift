import Foundation

struct GitHubClient {
    private let session: URLSession
    private let apiVersion: String

    init(
        session: URLSession = .shared,
        apiVersion: String = "2026-03-10"
    ) {
        self.session = session
        self.apiVersion = apiVersion
    }

    func installationToken(
        configuration: HelperConfiguration,
        privateKeyPEM: Data,
        now: Date = Date()
    ) async throws -> InstallationToken {
        let jwt = try JWTSigner(privateKeyPEM: privateKeyPEM)
            .token(clientID: configuration.clientID, now: now)
        guard let url = URL(
            string: "https://api.github.com/app/installations/"
                + configuration.installationID
                + "/access_tokens"
        ) else {
            throw HelperError.invalidConfiguration("installation ID is invalid")
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data("{}".utf8)
        request.setValue(
            "application/vnd.github+json",
            forHTTPHeaderField: "Accept"
        )
        request.setValue("Bearer \(jwt)", forHTTPHeaderField: "Authorization")
        request.setValue(apiVersion, forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue(
            "fcomrqz-github-token-manager",
            forHTTPHeaderField: "User-Agent"
        )
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HelperError.invalidResponse
        }
        guard (200 ..< 300).contains(httpResponse.statusCode) else {
            // Do not include GitHub's body: successful responses contain the
            // bearer token, and keeping one redaction rule is less error-prone.
            throw HelperError.githubStatus(httpResponse.statusCode)
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        guard decoded.token.hasPrefix("ghs_"),
              !decoded.token.contains(where: \.isWhitespace),
              let expiresAt = ISO8601DateFormatter().date(
                  from: decoded.expiresAt
              )
        else {
            throw HelperError.invalidResponse
        }
        return InstallationToken(value: decoded.token, expiresAt: expiresAt)
    }
}

private struct TokenResponse: Decodable {
    let token: String
    let expiresAt: String

    enum CodingKeys: String, CodingKey {
        case token
        case expiresAt = "expires_at"
    }
}
