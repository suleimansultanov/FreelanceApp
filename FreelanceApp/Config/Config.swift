import Foundation

struct Config {
    struct API {
        static let baseURL = "http://192.168.2.159:8000"
        static let secretKey = "secret-key-test"
        
        enum Endpoints {
            static let tasks = "/tasks/"
            static let proposals = "/proposals/"
            static let myTasks = "/tasks/me/"
            static let login = "/auth/token"
            static let register = "/auth/register"
            static let users = "/users"
            static let userInfo = "/users/info"
            static let myUserInfo = "/users/info/me"
            static let saveUserInfo = "/users/info"
            static let chats = "/chats/"
            static func chatMessages(_ chatId: String) -> String { "/messages/by-chat/\(chatId)" }
            static func sendChatMessage(_ chatId: String) -> String { "/messages/by-chat/\(chatId)/send" }
            static func markChatViewed(_ chatId: String) -> String { "/chats/\(chatId)/mark-viewed" }
            static let contracts = "/contracts/"
            static let myContracts = "/contracts/me"
            static func contractDetail(_ id: String) -> String { "/contracts/\(id)" }
            static func contractAccept(_ id: String) -> String { "/contracts/\(id)/accept" }
            static let feedback = "/feedback/"
            static func feedbackForUser(_ id: String) -> String { "/feedback/user/\(id)" }
            static let feedbackMe = "/feedback/me"
        }
        
        enum Headers {
            static let contentType = "Content-Type"
            static let authorization = "Authorization"
        }
        
        enum ContentType {
            static let formURLEncoded = "application/x-www-form-urlencoded"
            static let json = "application/json"
        }
    }
}	
