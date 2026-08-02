import Foundation

struct ConfigurationStore {
    private let fileManager: FileManager
    private let configurationURL: URL

    init(
        fileManager: FileManager = .default,
        configurationURL: URL = HelperPaths.configuration
    ) {
        self.fileManager = fileManager
        self.configurationURL = configurationURL
    }

    func load() throws -> HelperConfiguration {
        guard fileManager.fileExists(atPath: configurationURL.path) else {
            throw HelperError.missingConfiguration
        }
        let data = try Data(contentsOf: configurationURL)
        return try JSONDecoder().decode(HelperConfiguration.self, from: data)
    }

    func save(_ configuration: HelperConfiguration) throws {
        try fileManager.createPrivateDirectory(
            at: configurationURL.deletingLastPathComponent()
        )
        let data = try JSONEncoder.pretty.encode(configuration)
        try data.write(to: configurationURL, options: .atomic)
        try fileManager.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: configurationURL.path
        )
    }

    func remove() throws {
        guard fileManager.fileExists(atPath: configurationURL.path) else {
            return
        }
        try fileManager.removeItem(at: configurationURL)
    }
}

private extension JSONEncoder {
    static var pretty: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }
}
