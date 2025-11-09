import Foundation
import Combine
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentUsername: String?
    @Published var currentUserId: String?
    @Published var tasksCompleted: Int?
    @Published var rating: Double?
    
    private var token: TokenResponse?
    private let tokenKey = "authToken"
    private let usernameKey = "currentUsername"
    private let userIdKey = "currentUserId"
    private let secretKey = "secret-key-test"
    
    init() {
        currentUsername = UserDefaults.standard.string(forKey: usernameKey)
        currentUserId = UserDefaults.standard.string(forKey: userIdKey)
        
        // Check for existing token in UserDefaults
        if let savedToken = UserDefaults.standard.string(forKey: tokenKey) {
            let cleanToken = Self.cleanToken(savedToken)
            let restoredToken = TokenResponse(accessToken: cleanToken, tokenType: "")
            self.token = restoredToken
            self.isAuthenticated = true
            
            if currentUserId == nil {
                updateUserInfo(from: restoredToken)
            }
            
            refreshCurrentUserInfo()
        }
    }
    
    func register(username: String, password: String) {
        isLoading = true
        error = nil
        
        // Save credentials before registration attempt
        saveLastCredentials(username: username, password: password)
        
        let registrationData: [String: String] = [
            "grant_type": "password",
            "username": username,
            "password": password
        ]
        
        var urlComponents = URLComponents(string: Config.API.baseURL + Config.API.Endpoints.register)
        let queryItems = registrationData.map { URLQueryItem(name: $0.key, value: $0.value) }
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else {
            self.error = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = registrationData.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.isLoading = false
                    self?.error = error.localizedDescription
                    self?.clearLastCredentials()
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.isLoading = false
                    self?.error = "Invalid response"
                    self?.clearLastCredentials()
                    return
                }
                
                guard let data = data else {
                    self?.isLoading = false
                    self?.error = "No data received"
                    self?.clearLastCredentials()
                    return
                }
                
                do {
                    if httpResponse.statusCode == 422 {
                        let validationError = try JSONDecoder().decode(ValidationError.self, from: data)
                        let errorMessages = validationError.detail.map { "\($0.msg) (at \($0.loc.joined(separator: ".")))" }
                        self?.error = errorMessages.joined(separator: "\n")
                        self?.clearLastCredentials()
                        self?.isLoading = false
                    } else if (200...299).contains(httpResponse.statusCode) {
                        // Handle successful registration
                        let registrationResponse = try JSONDecoder().decode([String: String].self, from: data)
                        print("Successfully registered user with ID: \(registrationResponse["user_id"] ?? "")")
                        
                        // After successful registration, automatically login with saved credentials
                        if let username = self?.getLastUsername(),
                           let password = self?.getLastPassword() {
                            // Don't set isLoading to false here, as we're continuing with login
                            self?.loginWithEmailAndPassword(email: username, password: password)
                        } else {
                            self?.isLoading = false
                            self?.error = "Failed to auto-login after registration"
                            self?.clearLastCredentials()
                        }
                    } else {
                        // Handle other error responses
                        if let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                           let errorMessage = errorResponse["detail"] {
                            self?.error = errorMessage
                        } else {
                            self?.error = "Registration failed: \(httpResponse.statusCode)"
                        }
                        self?.clearLastCredentials()
                        self?.isLoading = false
                    }
                } catch {
                    self?.error = "Failed to decode response: \(error.localizedDescription)"
                    self?.clearLastCredentials()
                    self?.isLoading = false
                }
            }
        }.resume()
    }
    
    func loginWithEmailAndPassword(email: String, password: String) {
        isLoading = true
        error = nil
        
        let loginData: [String: String] = [
            "grant_type": "password",
            "username": email,
            "password": password
        ]
        
        guard let url = URL(string: Config.API.baseURL + Config.API.Endpoints.login) else {
            self.error = "Invalid URL"
            self.isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let bodyString = loginData.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        request.httpBody = bodyString.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.error = "Invalid response"
                    return
                }
                
                guard let data = data else {
                    self?.error = "No data received"
                    return
                }
                
                if httpResponse.statusCode == 422 {
                    do {
                        let validationError = try JSONDecoder().decode(ValidationError.self, from: data)
                        let errorMessages = validationError.detail.map { "\($0.msg) (at \($0.loc.joined(separator: ".")))" }
                        self?.error = errorMessages.joined(separator: "\n")
                    } catch {
                        self?.error = "Validation error occurred"
                    }
                    return
                }
                
                if (200...299).contains(httpResponse.statusCode) {
                    do {
                        let tokenResponse = try JSONDecoder().decode(TokenResponse.self, from: data)
                        
                        // Persist token (normalized)
                        let cleanToken = Self.cleanToken(tokenResponse.accessToken)
                        UserDefaults.standard.set(cleanToken, forKey: self?.tokenKey ?? "")
                        print("token:\(cleanToken)")
                        
                        // Update state
                        let normalizedToken = TokenResponse(accessToken: cleanToken, tokenType: tokenResponse.tokenType)
                        self?.token = normalizedToken
                        self?.isAuthenticated = true
                        self?.currentUsername = email
                        UserDefaults.standard.set(email, forKey: self?.usernameKey ?? "")
                        
                        self?.updateUserInfo(from: normalizedToken)
                        self?.refreshCurrentUserInfo()
                        
                        print("✅ Auth: Successfully decoded token. Type: \(tokenResponse.tokenType)")
                    } catch {
                        self?.error = "Failed to parse authentication response"
                        print("❌ Auth decode error: \(error.localizedDescription)")
                    }
                } else {
                    // Try to parse error message
                    if let errorMessage = String(data: data, encoding: .utf8) {
                        self?.error = errorMessage
                    } else {
                        self?.error = "Login failed: \(httpResponse.statusCode)"
                    }
                }
            }
        }.resume()
    }
    
    private func saveLastCredentials(username: String, password: String) {
        UserDefaults.standard.set(username, forKey: "lastUsername")
        UserDefaults.standard.set(password, forKey: "lastPassword")
    }
    
    private func getLastUsername() -> String? {
        return UserDefaults.standard.string(forKey: "lastUsername")
    }
    
    private func getLastPassword() -> String? {
        return UserDefaults.standard.string(forKey: "lastPassword")
    }
    
    private func clearLastCredentials() {
        UserDefaults.standard.removeObject(forKey: "lastUsername")
        UserDefaults.standard.removeObject(forKey: "lastPassword")
    }
    
    func logout() {
        token = nil
        isAuthenticated = false
        currentUsername = nil
        currentUserId = nil
        tasksCompleted = nil
        rating = nil
        clearLastCredentials()
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: usernameKey)
        UserDefaults.standard.removeObject(forKey: userIdKey)
    }
    
    func getAuthorizationHeader() -> String? {
        var accessToken: String?
        
        // Prefer the in-memory token
        if let storedToken = token, !storedToken.accessToken.isEmpty {
            accessToken = storedToken.accessToken
        } else if let savedToken = UserDefaults.standard.string(forKey: tokenKey), !savedToken.isEmpty {
            // Fall back to UserDefaults-stored token
            accessToken = savedToken
        }
        
        guard let token = accessToken, !token.isEmpty else {
            return nil
        }
        
        // Clean the token: remove quotes, whitespace, and newlines
        let cleanToken = Self.cleanToken(token)
        
        guard !cleanToken.isEmpty else {
            return nil
        }
        
        return "Bearer \(cleanToken)"
    }
    
    private static func cleanToken(_ token: String) -> String {
        let trimmed = token
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        var cleaned = trimmed
        
        func removePrefix(_ prefix: String) {
            if cleaned.lowercased().hasPrefix(prefix.lowercased()) {
                cleaned = String(cleaned.dropFirst(prefix.count))
                cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        removePrefix("bearer ")
        removePrefix("bearer:")
        removePrefix("token ")
        removePrefix("token:")
        
        // Remove any embedded whitespace/newline characters
        cleaned = cleaned.components(separatedBy: .whitespacesAndNewlines).joined()
        
        return cleaned
    }
    
    private func updateUserInfo(from tokenResponse: TokenResponse) {
        guard let payload = tokenResponse.decodeJWT() else { return }
        
        if let userId = payload["id"] as? String {
            currentUserId = userId
            UserDefaults.standard.set(userId, forKey: userIdKey)
        }
        
        if let username = payload["sub"] as? String {
            currentUsername = username
            UserDefaults.standard.set(username, forKey: usernameKey)
        }
    }
    
    func loginWithApple() {
        // Implement Apple login
    }
    
    func loginWithVK() {
        // Implement VK login
    }
    
    func loginWithGoogle() {
        // Implement Google login
    }
    
    func refreshCurrentUserInfo() {
        guard let authHeader = getAuthorizationHeader() else { return }
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.myUserInfo,
            authHeader: authHeader
        ) { [weak self] (result: Result<UserProfileInfo, NetworkError>) in
            switch result {
            case .success(let info):
                self?.tasksCompleted = info.tasksCompleted
                self?.rating = info.rating
            case .failure:
                self?.tasksCompleted = nil
                self?.rating = nil
            }
        }
    }
    
    func saveUserInfo(_ info: UserProfileInfo, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        guard let authHeader = getAuthorizationHeader() else {
            completion(.failure(.customError("Authentication required. Please log in.")))
            return
        }
        
        let body: [String: Any] = info.dictionaryRepresentation
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.saveUserInfo,
            method: .post,
            body: body,
            authHeader: authHeader
        ) { (result: Result<UserProfileInfo, NetworkError>) in
            switch result {
            case .success(let info):
                self.tasksCompleted = info.tasksCompleted ?? self.tasksCompleted
                self.rating = info.rating ?? self.rating
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

public struct UserProfileInfo: Codable {
    var phone: String = ""
    var firstName: String = ""
    var lastName: String = ""
    var middleName: String = ""
    var email: String = ""
    var address: String = ""
    var gender: String = ""
    var age: Int = 0
    var country: String = ""
    var tasksCompleted: Int?
    var rating: Double?
    
    var dictionaryRepresentation: [String: Any] {
        [
            "phone": phone,
            "firstName": firstName,
            "lastName": lastName,
            "middleName": middleName,
            "email": email,
            "address": address,
            "gender": gender,
            "age": age,
            "country": country
        ]
    }
}
