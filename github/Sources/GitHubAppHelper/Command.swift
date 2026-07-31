import Foundation

@main
struct GitHubAppHelperCommand {
    static func main() async {
        do {
            try await run(arguments: Array(CommandLine.arguments.dropFirst()))
        } catch {
            FileHandle.standardError.write(
                Data("github-app-helper: \(error.localizedDescription)\n".utf8)
            )
            exit(error is HelperError ? 2 : 1)
        }
    }

    private static func run(arguments: [String]) async throws {
        guard let command = arguments.first else {
            throw HelperError.usage(usage)
        }
        switch command {
        case "configure":
            try configure(Array(arguments.dropFirst()))
        case "run":
            await TokenDaemon().run()
        case "once":
            try await TokenDaemon().runOnce()
        case "status":
            try status(quiet: arguments.dropFirst().first == "--quiet")
        case "config":
            try printConfigurationValue(Array(arguments.dropFirst()))
        case "reset":
            try KeychainStore().removePrivateKey()
            try ConfigurationStore().remove()
        case "help", "--help", "-h":
            print(usage)
        default:
            throw HelperError.usage(usage)
        }
    }

    private static func configure(_ arguments: [String]) throws {
        guard arguments.count == 5 else {
            throw HelperError.usage(usage)
        }
        let configuration = HelperConfiguration(
            clientID: try Validation.clientID(arguments[0]),
            installationID: try Validation.numericID(
                arguments[1],
                name: "installation ID"
            ),
            machine: try Validation.machineName(arguments[2]),
            user: try Validation.userName(arguments[3])
        )
        let keyURL = URL(fileURLWithPath: arguments[4])
        let values = try keyURL.resourceValues(
            forKeys: [.isRegularFileKey, .isSymbolicLinkKey]
        )
        guard values.isRegularFile == true, values.isSymbolicLink != true else {
            throw HelperError.invalidPrivateKey(
                "the supplied path must be a regular, non-symlink file"
            )
        }
        let privateKey = try Data(contentsOf: keyURL)

        // Store the key first; configuration is the commit point that makes a
        // LaunchAgent run valid.
        try KeychainStore().savePrivateKey(privateKey)
        try ConfigurationStore().save(configuration)
        print("Configured GitHub App \(configuration.clientID) for \(configuration.machine).")
        print("The original PEM file was not removed.")
    }

    private static func status(quiet: Bool) throws {
        let configuration = try ConfigurationStore().load()
        guard KeychainStore().containsPrivateKey() else {
            throw HelperError.missingPrivateKey
        }
        if !quiet {
            print("configured=true")
            print("client_id=\(configuration.clientID)")
            print("installation_id=\(configuration.installationID)")
            print("machine=\(configuration.machine)")
            print("user=\(configuration.user)")
            print("private_key=keychain")
        }
    }

    private static func printConfigurationValue(_ arguments: [String]) throws {
        guard arguments.count == 1 else {
            throw HelperError.usage(usage)
        }
        let configuration = try ConfigurationStore().load()
        switch arguments[0] {
        case "machine":
            print(configuration.machine)
        case "user":
            print(configuration.user)
        case "client-id", "app-id":
            print(configuration.clientID)
        case "installation-id":
            print(configuration.installationID)
        default:
            throw HelperError.usage(usage)
        }
    }

    private static let usage = """
    Usage:
      github-app-helper configure CLIENT_ID INSTALLATION_ID MACHINE USER PRIVATE_KEY
      github-app-helper run
      github-app-helper once
      github-app-helper status [--quiet]
      github-app-helper config machine|user|client-id|installation-id
      github-app-helper reset
    """
}
