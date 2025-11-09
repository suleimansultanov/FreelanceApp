import Foundation
import Combine

struct ChatSummary: Identifiable, Decodable {
    let id: String
    let userOneId: String
    let userTwoId: String
    let createdAt: String
    let lastMessage: String?
    let lastMessageAt: String?
    let lastMessageSenderName: String?
    let lastMessageIsViewed: Bool?
    let participantName: String?
    
    var formattedDate: String {
        guard let lastMessageAt else { return "" }
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFraction.date(from: lastMessageAt) {
            return Self.displayFormatter.string(from: date)
        }
        let formatterWithoutFraction = ISO8601DateFormatter()
        formatterWithoutFraction.formatOptions = [.withInternetDateTime]
        if let date = formatterWithoutFraction.date(from: lastMessageAt) {
            return Self.displayFormatter.string(from: date)
        }
        return lastMessageAt
    }
    
    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()
}

class MessagesViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [User] = []
    @Published var isSearching = false
    @Published var error: String?
    @Published var showDropdown = false
    @Published var chats: [ChatSummary] = []
    @Published var isLoadingChats = false
    @Published var selectedUser: User?
    
    private var searchCancellable: AnyCancellable?
    private var authViewModel: AuthViewModel
    
    var authViewModelReference: AuthViewModel { authViewModel }
    var currentUsername: String? { authViewModel.currentUsername }
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        setupSearchSubscription()
        loadChats()
    }
    
    private func setupSearchSubscription() {
        searchCancellable = $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .sink { [weak self] searchTerm in
                if !searchTerm.isEmpty {
                    self?.searchUsers(searchTerm: searchTerm)
                } else {
                    self?.searchResults = []
                    self?.showDropdown = false
                }
            }
    }
    
    func refreshChats() {
        loadChats()
    }
    
    private func loadChats() {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            error = "Authentication required. Please log in."
            chats = []
            return
        }
        
        isLoadingChats = true
        error = nil
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.chats,
            authHeader: authHeader
        ) { [weak self] (result: Result<[ChatSummary], NetworkError>) in
            guard let self = self else { return }
            self.isLoadingChats = false
            
            switch result {
            case .success(let chats):
                self.chats = chats
            case .failure(let error):
                self.error = error.message
                self.chats = []
            }
        }
    }
    
    func searchUsers(searchTerm: String) {
        isSearching = true
        error = nil
        
        NetworkManager.shared.request(
            endpoint: "/users/search?q=\(searchTerm)",
            authHeader: authViewModel.getAuthorizationHeader()
        ) { [weak self] (result: Result<[User], NetworkError>) in
            self?.isSearching = false
            
            switch result {
            case .success(let users):
                self?.searchResults = users
                self?.showDropdown = !users.isEmpty
            case .failure(let error):
                self?.error = error.message
                self?.showDropdown = false
            }
        }
    }
    
    func selectUser(_ user: User) {
        selectedUser = user
        showDropdown = false
    }
    
    func dismissDropdown() {
        showDropdown = false
    }
    
    func clearSelectedUser() {
        selectedUser = nil
    }
}
