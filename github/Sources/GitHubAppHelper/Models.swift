import Foundation
import Security

struct HelperConfiguration: Codable, Equatable {
    let clientID: String
    let installationID: String
    let machine: String
    let user: String

    enum CodingKeys: String, CodingKey {
        case clientID = "client_id"
        case legacyAppID = "app_id"
        case installationID = "installation_id"
        case machine
        case user
    }

    init(
        clientID: String,
        installationID: String,
        machine: String,
        user: String
    ) {
        self.clientID = clientID
        self.installationID = installationID
        self.machine = machine
        self.user = user
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        clientID = try values.decodeIfPresent(
            String.self,
            forKey: .clientID
        ) ?? values.decode(String.self, forKey: .legacyAppID)
        installationID = try values.decode(
            String.self,
            forKey: .installationID
        )
        machine = try values.decode(String.self, forKey: .machine)
        user = try values.decode(String.self, forKey: .user)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(clientID, forKey: .clientID)
        try values.encode(installationID, forKey: .installationID)
        try values.encode(machine, forKey: .machine)
        try values.encode(user, forKey: .user)
    }
}

struct InstallationToken: Equatable {
    let value: String
    let expiresAt: Date
}

enum HelperError: LocalizedError {
    case usage(String)
    case invalidConfiguration(String)
    case missingConfiguration
    case missingPrivateKey
    case invalidPrivateKey(String)
    case keychain(OSStatus)
    case signing(String)
    case invalidResponse
    case githubStatus(Int)
    case orbUnavailable
    case deliveryFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case let .usage(message):
            return message
        case let .invalidConfiguration(message):
            return "Invalid configuration: \(message)"
        case .missingConfiguration:
            return "GitHub App helper is not configured."
        case .missingPrivateKey:
            return "The GitHub App private key is missing from Keychain."
        case let .invalidPrivateKey(message):
            return "Invalid GitHub App private key: \(message)"
        case let .keychain(status):
            let description = SecCopyErrorMessageString(status, nil) as String?
            return "Keychain operation failed: \(description ?? String(status))"
        case let .signing(message):
            return "JWT signing failed: \(message)"
        case .invalidResponse:
            return "GitHub returned an invalid installation-token response."
        case let .githubStatus(status):
            return "GitHub installation-token request failed with HTTP \(status)."
        case .orbUnavailable:
            return "The OrbStack command could not be found."
        case let .deliveryFailed(status, message):
            let suffix = message.isEmpty ? "" : ": \(message)"
            return "OrbStack token delivery failed with status \(status)\(suffix)"
        }
    }
}

enum HelperPaths {
    static let applicationName = "com.fcomrqz.github-app"
    static let keychainService = applicationName
    static let keychainAccount = "private-key-pem"
    static let launchAgentLabel = applicationName

    static var applicationSupportDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support", isDirectory: true)
            .appendingPathComponent(applicationName, isDirectory: true)
    }

    static var configuration: URL {
        applicationSupportDirectory.appendingPathComponent("config.json")
    }
}

enum Validation {
    static func clientID(_ value: String) throws -> String {
        let allowed = CharacterSet.alphanumerics.union(
            CharacterSet(charactersIn: "._-")
        )
        guard !value.isEmpty,
              value.count <= 128,
              value.unicodeScalars.allSatisfy(allowed.contains)
        else {
            throw HelperError.invalidConfiguration(
                "client ID must contain only letters, digits, '.', '_', or '-'"
            )
        }
        return value
    }

    static func numericID(_ value: String, name: String) throws -> String {
        guard !value.isEmpty, value.allSatisfy(\.isNumber) else {
            throw HelperError.invalidConfiguration("\(name) must contain only decimal digits")
        }
        return value
    }

    static func machineName(_ value: String) throws -> String {
        try identifier(value, name: "machine")
    }

    static func userName(_ value: String) throws -> String {
        try identifier(value, name: "user")
    }

    private static func identifier(_ value: String, name: String) throws -> String {
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "._-"))
        guard let first = value.unicodeScalars.first,
              CharacterSet.alphanumerics.contains(first),
              !value.isEmpty,
              value.unicodeScalars.allSatisfy(allowed.contains)
        else {
            throw HelperError.invalidConfiguration(
                "\(name) must start with a letter or digit and contain only letters, digits, '.', '_', or '-'"
            )
        }
        return value
    }
}

extension FileManager {
    func createPrivateDirectory(at url: URL) throws {
        try createDirectory(
            at: url,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
    }
}
