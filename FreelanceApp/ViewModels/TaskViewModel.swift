import Foundation
import Combine

class TaskViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filteredTasks: [Task] = []
    @Published var isLoading = false
    @Published var selectedFilter: TaskFilter = .all
    @Published var searchText = ""
    @Published var error: String?
    @Published private(set) var deletingTaskIDs: Set<String> = []
    
    @Published var selectedCategory: TaskCategory?
    @Published var selectedStatus: TaskStatus?
    @Published var minPrice: Double?
    @Published var maxPrice: Double?
    @Published var onlyRemote = false
    @Published var hideWithResponses = false
    
    private var cancellables = Set<AnyCancellable>()
    public var authViewModel: AuthViewModel
    
    enum TaskFilter {
        case all
        case recommended
    }
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        loadTasks()
        
        // Setup search publisher
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .sink { [weak self] searchText in
                self?.filterTasks(searchText: searchText)
            }
            .store(in: &cancellables)
    }
    
    func isTaskOwnedByCurrentUser(_ task: Task) -> Bool {
        if let ownerId = task.ownerId, let currentUserId = authViewModel.currentUserId {
            if ownerId == currentUserId {
                return true
            }
        }
        
        if let ownerUsername = task.ownerUsername, let currentUsername = authViewModel.currentUsername {
            return ownerUsername == currentUsername
        }
        
        return false
    }
    
    func isDeleting(task: Task) -> Bool {
        deletingTaskIDs.contains(task.id)
    }
    
    func loadTasks() {
        isLoading = true
        error = nil
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.tasks,
            authHeader: authViewModel.getAuthorizationHeader()
        ) { [weak self] (result: Result<[Task], NetworkError>) in
            self?.isLoading = false
            
            switch result {
            case .success(let tasks):
                self?.tasks = tasks
                self?.filterTasks(searchText: self?.searchText ?? "")
            case .failure(let error):
                self?.error = error.message
            }
        }
    }
    
    func filterTasks(searchText: String) {
        if searchText.isEmpty {
            filteredTasks = tasks
            return
        }
        
        filteredTasks = tasks.filter { task in
            let searchQuery = searchText.lowercased()
            return task.title.lowercased().contains(searchQuery) ||
                   task.category.displayName.lowercased().contains(searchQuery) ||
                   task.formattedPrice.lowercased().contains(searchQuery) ||
                   (task.isRemote && "удаленно".contains(searchQuery)) ||
                   (!task.hasResponses && "без откликов".contains(searchQuery))
        }
    }
    
    func createTask(title: String, description: String, location: String, price: Double, startDate: String, endDate: String, category: TaskCategory, isRemote: Bool) {
        isLoading = true
        error = nil
        
        // Ensure we have an auth token before making the request
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            isLoading = false
            error = "Authentication required. Please log in."
            print("❌ Create Task: No authorization header available")
            return
        }
        
        print("✅ Create Task: Authorization header retrieved.")
        
        let taskData: [String: Any] = [
            "title": title,
            "description": description,
            "location": location,
            "price": price,
            "startDate": startDate,
            "endDate": endDate,
            "category": category.rawValue,
            "status": "open",
            "hasResponses": false,
            "isRemote": isRemote
        ]
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.tasks,
            method: .post,
            body: taskData,
            authHeader: authHeader
        ) { [weak self] (result: Result<Task, NetworkError>) in
            self?.isLoading = false
            
            switch result {
            case .success:
                self?.loadTasks()
            case .failure(let networkError):
                if case .serverError(let statusCode, let data) = networkError, statusCode == 422, let data = data {
                    do {
                        let decoder = JSONDecoder()
                        let validationError = try decoder.decode(ValidationError.self, from: data)
                        let errorMessages = validationError.detail.map { detail -> String in
                            if let fieldName = detail.loc.last {
                                return "\(fieldName): \(detail.msg)"
                            }
                            return detail.msg
                        }
                        self?.error = errorMessages.joined(separator: "\n")
                    } catch {
                        // If we can't decode the validation error, try to decode as a simple message
                        if let errorString = String(data: data, encoding: .utf8) {
                            self?.error = errorString
                        } else {
                            self?.error = "Validation error occurred"
                        }
                    }
                } else {
                    self?.error = networkError.message
                }
            }
        }
    }
    
    func deleteTask(_ task: Task) {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            error = "Authentication required. Please log in."
            return
        }
        
        deletingTaskIDs.insert(task.id)
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.tasks + "\(task.id)",
            method: .delete,
            authHeader: authHeader
        ) { [weak self] (result: Result<EmptyResponse, NetworkError>) in
            guard let self = self else { return }
            
            self.deletingTaskIDs.remove(task.id)
            
            switch result {
            case .success:
                self.removeTaskLocally(withId: task.id)
            case .failure(let error):
                self.error = error.message
            }
        }
    }
    
    // Helper function to convert date string to Date object
    private func dateStringToDate(_ dateString: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            return date
        }
        // Fallback: try without fractional seconds
        isoFormatter.formatOptions = [.withInternetDateTime]
        return isoFormatter.date(from: dateString)
    }
    
    func updateAuthViewModel(_ newAuthViewModel: AuthViewModel) {
        self.authViewModel = newAuthViewModel
        loadTasks()
    }
    
    func removeTaskLocally(withId id: String) {
        tasks.removeAll { $0.id == id }
        filterTasks(searchText: searchText)
    }
}
