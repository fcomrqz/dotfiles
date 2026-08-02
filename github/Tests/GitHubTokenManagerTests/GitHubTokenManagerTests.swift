import Foundation
import Security
import XCTest
@testable import GitHubTokenManager

final class GitHubTokenManagerTests: XCTestCase {
    func testBase64URLRemovesPaddingAndUnsafeCharacters() {
        XCTAssertEqual(Data([0xfb, 0xff]).base64URL, "-_8")
    }

    func testOrbArgumentsNeverContainTheToken() throws {
        let configuration = HelperConfiguration(
            clientID: "Iv1.example",
            installationID: "456",
            machine: "ubuntu",
            user: "fcomrqz"
        )
        let token = InstallationToken(
            value: "ghs_secret-value",
            expiresAt: Date(timeIntervalSince1970: 2_000_000_000)
        )

        XCTAssertFalse(
            OrbTokenDelivery.arguments(configuration: configuration)
                .contains(where: { $0.contains(token.value) })
        )
        let environment = OrbTokenDelivery.environment(token: token, base: [:])
        XCTAssertEqual(
            environment[OrbTokenDelivery.tokenEnvironment],
            token.value
        )
        XCTAssertEqual(
            environment["ORBENV"],
            "FCRQZ_GITHUB_APP_TOKEN:FCRQZ_GITHUB_APP_TOKEN_EXPIRES_AT"
        )
    }

    func testConfigurationValidation() throws {
        XCTAssertEqual(
            try Validation.machineName("ubuntu-26.04"),
            "ubuntu-26.04"
        )
        XCTAssertThrowsError(try Validation.machineName("../ubuntu"))
        XCTAssertThrowsError(
            try Validation.numericID("12x", name: "installation ID")
        )
        XCTAssertEqual(
            try Validation.clientID("Iv1.0123456789abcdef"),
            "Iv1.0123456789abcdef"
        )
        XCTAssertThrowsError(try Validation.clientID("client/id"))
    }

    func testConfigurationIsStoredPrivately() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("config.json")
        let store = ConfigurationStore(configurationURL: url)
        let configuration = HelperConfiguration(
            clientID: "Iv1.example",
            installationID: "456",
            machine: "ubuntu",
            user: "fcomrqz"
        )

        try store.save(configuration)

        XCTAssertEqual(try store.load(), configuration)
        let attributes = try FileManager.default.attributesOfItem(
            atPath: url.path
        )
        XCTAssertEqual(
            (attributes[.posixPermissions] as? NSNumber)?.intValue,
            0o600
        )
    }

    func testJWTContainsExpectedClaimsAndVerifiableSignature() throws {
        let pem = try generatePrivateKey()
        let privateKey = try PrivateKeyLoader.securityKey(fromPEM: pem)
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        let token = try JWTSigner(privateKeyPEM: pem)
            .token(clientID: "Iv1.0123456789abcdef", now: now)
        let components = token.split(separator: ".")
        XCTAssertEqual(components.count, 3)

        let payload = try XCTUnwrap(decodeBase64URL(String(components[1])))
        let claims = try XCTUnwrap(
            JSONSerialization.jsonObject(with: payload) as? [String: Any]
        )
        XCTAssertEqual(
            claims["iss"] as? String,
            "Iv1.0123456789abcdef"
        )
        XCTAssertEqual(claims["iat"] as? Int, 1_899_999_940)
        XCTAssertEqual(claims["exp"] as? Int, 1_900_000_540)

        let signingInput = Data(
            "\(components[0]).\(components[1])".utf8
        )
        let signature = try XCTUnwrap(
            decodeBase64URL(String(components[2]))
        )
        let publicKey = try XCTUnwrap(SecKeyCopyPublicKey(privateKey))
        var verifyError: Unmanaged<CFError>?
        XCTAssertTrue(
            SecKeyVerifySignature(
                publicKey,
                .rsaSignatureMessagePKCS1v15SHA256,
                signingInput as CFData,
                signature as CFData,
                &verifyError
            )
        )
    }

    func testPKCS8PrivateKeyCanBeLoaded() throws {
        let traditionalPEM = try generatePrivateKey()
        let process = Process()
        let input = Pipe()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/openssl")
        process.arguments = ["pkcs8", "-topk8", "-nocrypt"]
        process.standardInput = input
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        input.fileHandleForWriting.write(traditionalPEM)
        try input.fileHandleForWriting.close()
        let pkcs8PEM = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        XCTAssertNoThrow(
            try PrivateKeyLoader.securityKey(fromPEM: pkcs8PEM)
        )
    }

    private func generatePrivateKey() throws -> Data {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/openssl")
        process.arguments = ["genrsa", "2048"]
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        try process.run()
        let pem = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        XCTAssertEqual(process.terminationStatus, 0)
        return pem
    }

    private func decodeBase64URL(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        base64 += String(repeating: "=", count: (4 - base64.count % 4) % 4)
        return Data(base64Encoded: base64)
    }
}
