import Foundation
import CoreImage

struct QRCodeParser {
    
    struct ParsedOTP {
        let issuer: String
        let accountName: String
        let secret: String
    }
    
    /// Parse otpauth:// URL from QR code
    static func parse(otpAuthURL: String) -> ParsedOTP? {
        guard otpAuthURL.hasPrefix("otpauth://totp/") || otpAuthURL.hasPrefix("otpauth://hotp/") else {
            return nil
        }
        
        guard let url = URL(string: otpAuthURL) else { return nil }
        
        // Extract label from path
        // Format: otpauth://totp/Issuer:account@service?secret=XXX&issuer=Issuer
        let label = url.lastPathComponent.removingPercentEncoding ?? ""
        
        // Parse query parameters
        guard let components = URLComponents(string: otpAuthURL),
              let items = components.queryItems,
              let secret = items.first(where: { $0.name == "secret" })?.value else {
            return nil
        }
        
        // Get issuer from query param, or from label
        var issuer = items.first(where: { $0.name == "issuer" })?.value ?? ""
        var accountName = label
        
        // Try to split label into issuer:account
        if !label.isEmpty {
            let parts = label.components(separatedBy: ":")
            if parts.count == 2 {
                if issuer.isEmpty {
                    issuer = parts[0]
                }
                accountName = parts[1]
            }
        }
        
        if issuer.isEmpty {
            issuer = "未知发行方"
        }
        if accountName.isEmpty {
            accountName = "账号"
        }
        
        return ParsedOTP(issuer: issuer, accountName: accountName, secret: secret)
    }
    
    /// Detect QR code from UIImage
    static func detectQRCode(in image: CIImage) -> String? {
        let context = CIContext()
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: context, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        
        let features = detector?.features(in: image) ?? []
        for feature in features {
            if let qrFeature = feature as? CIQRCodeFeature, let message = qrFeature.messageString {
                return message
            }
        }
        return nil
    }
}
