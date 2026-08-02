import Foundation

struct TokenDaemon {
    private let configurationStore: ConfigurationStore
    private let keychainStore: KeychainStore
    private let githubClient: GitHubClient
    private let delivery: OrbTokenDelivery

    init(
        configurationStore: ConfigurationStore = ConfigurationStore(),
        keychainStore: KeychainStore = KeychainStore(),
        githubClient: GitHubClient = GitHubClient(),
        delivery: OrbTokenDelivery = OrbTokenDelivery()
    ) {
        self.configurationStore = configurationStore
        self.keychainStore = keychainStore
        self.githubClient = githubClient
        self.delivery = delivery
    }

    func run() async -> Never {
        var currentToken: InstallationToken?
        var activeConfiguration: HelperConfiguration?
        while true {
            do {
                let configuration = try configurationStore.load()
                if activeConfiguration != configuration {
                    currentToken = nil
                    activeConfiguration = configuration
                }
                let now = Date()
                if currentToken == nil
                    || currentToken!.expiresAt.timeIntervalSince(now) <= 15 * 60
                {
                    let privateKey = try keychainStore.loadPrivateKey()
                    currentToken = try await githubClient.installationToken(
                        configuration: configuration,
                        privateKeyPEM: privateKey,
                        now: now
                    )
                    log("Generated a GitHub App installation token.")
                }
                guard let token = currentToken else {
                    throw HelperError.invalidResponse
                }
                try delivery.deliver(token, configuration: configuration)
                log("Delivered GitHub authentication to \(configuration.machine).")

                // Re-deliver the cached token periodically so a restarted
                // machine receives it promptly without minting a new token.
                let delay = max(
                    60,
                    min(
                        5 * 60,
                        token.expiresAt.timeIntervalSinceNow - 15 * 60
                    )
                )
                try await Task.sleep(for: .seconds(delay))
            } catch {
                log(error.localizedDescription)
                // Keep launchd stable during network, Keychain, machine, and
                // provisioning outages. A new configuration takes effect on
                // the next retry without requiring a daemon restart.
                try? await Task.sleep(for: .seconds(60))
            }
        }
    }

    func runOnce() async throws {
        let configuration = try configurationStore.load()
        let privateKey = try keychainStore.loadPrivateKey()
        let token = try await githubClient.installationToken(
            configuration: configuration,
            privateKeyPEM: privateKey
        )
        try delivery.deliver(token, configuration: configuration)
        log("Delivered GitHub authentication to \(configuration.machine).")
    }
}

func log(_ message: String) {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    FileHandle.standardError.write(Data("[\(timestamp)] \(message)\n".utf8))
}
