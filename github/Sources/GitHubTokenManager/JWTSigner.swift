import Foundation
import Security

struct JWTSigner {
    let privateKey: SecKey

    init(privateKeyPEM: Data) throws {
        privateKey = try PrivateKeyLoader.securityKey(fromPEM: privateKeyPEM)
    }

    func token(clientID: String, now: Date = Date()) throws -> String {
        let header = try JSONSerialization.data(
            withJSONObject: ["alg": "RS256", "typ": "JWT"],
            options: [.sortedKeys]
        )
        let issuedAt = Int(now.timeIntervalSince1970) - 60
        // Stay below GitHub's ten-minute maximum even with clock skew.
        let expiresAt = Int(now.timeIntervalSince1970) + 9 * 60
        let payload = try JSONSerialization.data(
            withJSONObject: [
                "iat": issuedAt,
                "exp": expiresAt,
                "iss": clientID,
            ],
            options: [.sortedKeys]
        )
        let signingInput = "\(header.base64URL).\(payload.base64URL)"
        guard let signingData = signingInput.data(using: .utf8) else {
            throw HelperError.signing("could not encode JWT")
        }
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .rsaSignatureMessagePKCS1v15SHA256,
            signingData as CFData,
            &error
        ) as Data? else {
            let message = error?.takeRetainedValue().localizedDescription
                ?? "Security.framework rejected the signature"
            throw HelperError.signing(message)
        }
        return "\(signingInput).\(signature.base64URL)"
    }
}

enum PrivateKeyLoader {
    static func securityKey(fromPEM pem: Data) throws -> SecKey {
        guard let text = String(data: pem, encoding: .utf8) else {
            throw HelperError.invalidPrivateKey("PEM is not UTF-8")
        }
        let base64 = text
            .split(whereSeparator: \.isNewline)
            .filter { !$0.hasPrefix("-----") }
            .joined()
        guard let der = Data(base64Encoded: base64) else {
            throw HelperError.invalidPrivateKey("PEM body is not valid base64")
        }

        if let key = createSecurityKey(from: der) {
            return key
        }
        if let unwrapped = unwrapPKCS8(der),
           let key = createSecurityKey(from: unwrapped)
        {
            return key
        }
        throw HelperError.invalidPrivateKey(
            "expected an RSA private key in PKCS#1 or PKCS#8 format"
        )
    }

    private static func createSecurityKey(from der: Data) -> SecKey? {
        let attributes: [CFString: Any] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPrivate,
        ]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(
            der as CFData,
            attributes as CFDictionary,
            &error
        ) else {
            return nil
        }
        guard SecKeyIsAlgorithmSupported(
            key,
            .sign,
            .rsaSignatureMessagePKCS1v15SHA256
        ) else {
            return nil
        }
        return key
    }

    // PrivateKeyInfo ::= SEQUENCE { version, algorithm, privateKey OCTET STRING }
    private static func unwrapPKCS8(_ data: Data) -> Data? {
        var outer = DERReader(data)
        guard let sequence = outer.read(tag: 0x30) else {
            return nil
        }
        var fields = DERReader(sequence)
        guard fields.read(tag: 0x02) != nil,
              fields.read(tag: 0x30) != nil,
              let privateKey = fields.read(tag: 0x04)
        else {
            return nil
        }
        return privateKey
    }
}

private struct DERReader {
    private let data: Data
    private var offset = 0

    init(_ data: Data) {
        self.data = data
    }

    mutating func read(tag expectedTag: UInt8) -> Data? {
        guard offset < data.count, data[offset] == expectedTag else {
            return nil
        }
        offset += 1
        guard let length = readLength(), length >= 0,
              offset + length <= data.count
        else {
            return nil
        }
        let value = data.subdata(in: offset ..< offset + length)
        offset += length
        return value
    }

    private mutating func readLength() -> Int? {
        guard offset < data.count else {
            return nil
        }
        let first = Int(data[offset])
        offset += 1
        if first & 0x80 == 0 {
            return first
        }
        let byteCount = first & 0x7f
        guard byteCount > 0, byteCount <= MemoryLayout<Int>.size,
              offset + byteCount <= data.count
        else {
            return nil
        }
        var length = 0
        for _ in 0 ..< byteCount {
            length = (length << 8) | Int(data[offset])
            offset += 1
        }
        return length
    }
}

extension Data {
    var base64URL: String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
