import Foundation

struct TaskDetailResponse: Codable {
    let id: String
    let title: String
    let description: String
    let location: String
    let startDate: String
    let endDate: String?
    let category: TaskCategory
    let status: TaskStatus
    let hasResponses: Bool
    let isRemote: Bool
    let price: Double
    let create_date: String
}

class TaskDetailViewModel: ObservableObject {
    @Published var task: Task?
    @Published var isLoading = false
    @Published var error: String?
    @Published var createDate: String?
    @Published var taskDescription: String?
    @Published var taskLocation: String?
    
    private let taskId: String
    private let authViewModel: AuthViewModel
    
    init(taskId: String, authViewModel: AuthViewModel) {
        self.taskId = taskId
        self.authViewModel = authViewModel
        loadTaskDetails()
    }
    
    func loadTaskDetails() {
        isLoading = true
        error = nil
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.tasks + "\(taskId)",
            authHeader: authViewModel.getAuthorizationHeader()
        ) { [weak self] (result: Result<TaskDetailResponse, NetworkError>) in
            self?.isLoading = false
            
            switch result {
            case .success(let response):
                // Create Task from response
                self?.task = Task(
                    id: response.id,
                    title: response.title,
                    startDate: response.startDate,
                    endDate: response.endDate,
                    category: response.category,
                    status: response.status,
                    hasResponses: response.hasResponses,
                    isRemote: response.isRemote,
                    price: response.price
                )
                
                // Store additional details
                self?.createDate = response.create_date
                self?.taskDescription = response.description
                self?.taskLocation = response.location
            case .failure(let error):
                self?.error = error.message
            }
        }
    }
    
    func formatCreateDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd.MM.yyyy HH:mm"
        
        if let date = inputFormatter.date(from: dateString) {
            return outputFormatter.string(from: date)
        }
        return dateString
    }
}
