import Foundation
struct EmptyResponse: Decodable {
    init() {}
}

public enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError
    case customError(String)
    case serverError(Int, Data?)

    var message: String {
        switch self {
        case .invalidURL:
            return "Неверный адрес запроса."
        case .invalidResponse:
            return "Сервер вернул некорректный ответ."
        case .noData:
            return "Нет данных в ответе сервера."
        case .decodingError:
            return "Не удалось обработать данные сервера."
        case .customError(let msg):
            return msg
        case .serverError(let statusCode, _):
            return "Ошибка сервера (\(statusCode))."
        }
    }
}

final class NetworkManager {
    static let shared = NetworkManager()

    private init() {}


    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case patch = "PATCH"
        case delete = "DELETE"
    }

    func request<T: Decodable>(
        endpoint: String,
        method: HTTPMethod = .get,
        body: [String: Any]? = nil,
        authHeader: String?,
        completion: @escaping (Result<T, NetworkError>) -> Void
    ) {
        let urlString = Config.API.baseURL + endpoint
        guard let url = URL(string: urlString) else {
            completion(.failure(.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue

        if let authHeader = authHeader {
            request.setValue(authHeader, forHTTPHeaderField: Config.API.Headers.authorization)
            print("[NetworkManager] Setting Authorization header for \(method.rawValue) \(endpoint): \(authHeader)")
        } else {
            print(" [NetworkManager] No Authorization header provided for \(method.rawValue) \(endpoint)")
        }

        if let body = body {
            request.setValue(Config.API.ContentType.json, forHTTPHeaderField: Config.API.Headers.contentType)
            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: body)
                print(" [NetworkManager] Request body: \(body)")
            } catch {
                completion(.failure(.customError("Failed to encode request body")))
                return
            }
        }

        if let allHeaders = request.allHTTPHeaderFields {
            print(" [NetworkManager] Request headers:")
            for (key, value) in allHeaders {
                print("   \(key): \(value)")
            }
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(.customError(error.localizedDescription)))
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }

                guard (200...299).contains(httpResponse.statusCode) else {
                    if httpResponse.statusCode == 401 {
                        print(" [NetworkManager] 401 Unauthorized - Authentication failed")
                        if let data = data,
                           let errorString = String(data: data, encoding: .utf8) {
                            print("   Error response: \(errorString)")
                        }
                        completion(.failure(.customError("Authentication failed. Please log in again.")))
                        return
                    }

                    if let data = data,
                       let errorResponse = try? JSONDecoder().decode([String: String].self, from: data),
                       let errorMessage = errorResponse["detail"] {
                        print("[NetworkManager] Server error \(httpResponse.statusCode): \(errorMessage)")
                        completion(.failure(.customError(errorMessage)))
                    } else {
                        print("[NetworkManager] Server error \(httpResponse.statusCode) with no detail message")
                        completion(.failure(.serverError(httpResponse.statusCode, data)))
                    }
                    return
                }

                let responseData = data ?? Data()

                if responseData.isEmpty {
                    if T.self == EmptyResponse.self {
                        if let emptyResponse = EmptyResponse() as? T {
                            completion(.success(emptyResponse))
                        } else {
                            completion(.failure(.decodingError))
                        }
                        return
                    } else {
                        completion(.failure(.noData))
                        return
                    }
                }

                do {
                    let decodedResponse = try JSONDecoder().decode(T.self, from: responseData)
                    completion(.success(decodedResponse))
                } catch {
                    completion(.failure(.decodingError))
                }
            }
        }.resume()
    }
}
