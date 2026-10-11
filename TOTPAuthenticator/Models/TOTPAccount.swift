import Foundation

struct TOTPAccount: Identifiable, Codable, Hashable {
    let id: UUID
    var issuer: String
    var accountName: String
    var secret: String
    var timeStep: Int
    var digits: Int
    let dateAdded: Date
    
    init(id: UUID = UUID(), issuer: String, accountName: String, secret: String, timeStep: Int = 30, digits: Int = 6) {
        self.id = id
        self.issuer = issuer
        self.accountName = accountName
        self.secret = secret
        self.timeStep = timeStep
        self.digits = digits
        self.dateAdded = Date()
    }
    
    var displayCode: String {
        do {
            return try TOTPService.generate(secret: secret, timeStep: timeStep, digits: digits)
        } catch {
            return "------"
        }
    }
    
    var remainingSeconds: Int {
        TOTPService.remainingSeconds(timeStep: timeStep)
    }
}
