import Foundation
import CommonCrypto

struct TOTPService {
    
    enum TOTPError: Error {
        case invalidBase32Secret
        case hmacComputationFailed
    }
    
    /// Generate TOTP code from base32 secret
    static func generate(secret: String, timeStep: Int = 30, digits: Int = 6) throws -> String {
        let key = try base32Decode(secret)
        let counter = Int(Date().timeIntervalSince1970) / timeStep
        return hotp(key: key, counter: counter, digits: digits)
    }
    
    /// Get remaining seconds in current time step
    static func remainingSeconds(timeStep: Int = 30) -> Int {
        let current = Int(Date().timeIntervalSince1970)
        return timeStep - (current % timeStep)
    }
    
    /// HOTP algorithm (RFC 4226)
    private static func hotp(key: Data, counter: Int, digits: Int) -> String {
        var bigEndianCounter = UInt64(counter).bigEndian
        let counterData = Data(bytes: &bigEndianCounter, count: MemoryLayout<UInt64>.size)
        
        var hmac = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        key.withUnsafeBytes { keyBytes in
            counterData.withUnsafeBytes { counterBytes in
                CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1),
                       keyBytes.baseAddress, key.count,
                       counterBytes.baseAddress, counterData.count,
                       &hmac)
            }
        }
        
        let offset = Int(hmac[hmac.count - 1] & 0x0f)
        let binary = ((UInt32(hmac[offset] & 0x7f) << 24) |
                      (UInt32(hmac[offset + 1]) << 16) |
                      (UInt32(hmac[offset + 2]) << 8) |
                       UInt32(hmac[offset + 3]))
        
        let otp = binary % UInt32(pow(10.0, Double(digits)))
        return String(format: "%0\(digits)d", otp)
    }
    
    /// Decode base32 string to Data
    private static func base32Decode(_ string: String) throws -> Data {
        let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567"
        var cleaned = string.uppercased()
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "=", with: "")
        
        var result = Data()
        var buffer: UInt64 = 0
        var bitsLeft = 0
        
        for char in cleaned {
            guard let index = alphabet.firstIndex(of: char) else {
                throw TOTPError.invalidBase32Secret
            }
            let value = UInt64(alphabet.distance(from: alphabet.startIndex, to: index))
            buffer = (buffer << 5) | value
            bitsLeft += 5
            
            if bitsLeft >= 8 {
                bitsLeft -= 8
                result.append(UInt8((buffer >> bitsLeft) & 0xFF))
                buffer &= (1 << bitsLeft) - 1
            }
        }
        
        return result
    }
    
    /// Validate base32 secret format
    static func isValidSecret(_ secret: String) -> Bool {
        let cleaned = secret.uppercased().replacingOccurrences(of: " ", with: "")
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ234567")
        return !cleaned.isEmpty && cleaned.rangeOfCharacter(from: allowed.inverted) == nil
    }
}
