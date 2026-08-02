import Foundation

struct OrbTokenDelivery {
    static let guestWriter = "/usr/local/libexec/fcomrqz/github-token-store"
    static let tokenEnvironment = "FCRQZ_GITHUB_APP_TOKEN"
    static let expirationEnvironment = "FCRQZ_GITHUB_APP_TOKEN_EXPIRES_AT"

    private let executableCandidates: [String]

    init(executableCandidates: [String] = [
        "/opt/homebrew/bin/orb",
        "/usr/local/bin/orb",
        "/Applications/OrbStack.app/Contents/MacOS/bin/orb",
    ]) {
        self.executableCandidates = executableCandidates
    }

    func deliver(
        _ token: InstallationToken,
        configuration: HelperConfiguration
    ) throws {
        let process = Process()
        process.executableURL = try orbExecutable()
        process.arguments = Self.arguments(configuration: configuration)
        process.environment = Self.environment(
            token: token,
            base: ProcessInfo.processInfo.environment
        )
        process.standardOutput = FileHandle.nullDevice
        let errorPipe = Pipe()
        process.standardError = errorPipe
        try process.run()
        // Drain while the process runs so an unexpectedly verbose OrbStack
        // failure cannot fill the pipe and deadlock the helper.
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let message = String(data: errorData, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                ?? ""
            throw HelperError.deliveryFailed(
                Int(process.terminationStatus),
                Self.sanitize(message)
            )
        }
    }

    static func arguments(configuration: HelperConfiguration) -> [String] {
        [
            "-m", configuration.machine,
            "-u", configuration.user,
            guestWriter,
        ]
    }

    static func environment(
        token: InstallationToken,
        base: [String: String]
    ) -> [String: String] {
        var environment = base
        environment[tokenEnvironment] = token.value
        environment[expirationEnvironment] = ISO8601DateFormatter()
            .string(from: token.expiresAt)
        environment["ORBENV"] = [
            tokenEnvironment,
            expirationEnvironment,
        ].joined(separator: ":")
        return environment
    }

    private func orbExecutable() throws -> URL {
        for candidate in executableCandidates
        where FileManager.default.isExecutableFile(atPath: candidate) {
            return URL(fileURLWithPath: candidate)
        }
        throw HelperError.orbUnavailable
    }

    private static func sanitize(_ message: String) -> String {
        // Guest errors never intentionally include the token. Bound the text
        // anyway so unexpected command output cannot flood persistent logs.
        String(message.prefix(500))
    }
}
