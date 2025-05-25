import Foundation

enum ProjectStatus: String, Codable {
    case open
    case inProgress
    case completed
    case cancelled
}

struct Project: Identifiable, Codable {
    let id: UUID
    var title: String
    var description: String
    var budget: Double
    var deadline: Date?
    var requiredSkills: [String]
    var status: ProjectStatus
    var clientId: UUID
    var freelancerId: UUID?
    var createdAt: Date
    var category: String
    
    init(id: UUID = UUID(), title: String, description: String, budget: Double,
         deadline: Date? = nil, requiredSkills: [String], status: ProjectStatus = .open,
         clientId: UUID, freelancerId: UUID? = nil, createdAt: Date = Date(), category: String) {
        self.id = id
        self.title = title
        self.description = description
        self.budget = budget
        self.deadline = deadline
        self.requiredSkills = requiredSkills
        self.status = status
        self.clientId = clientId
        self.freelancerId = freelancerId
        self.createdAt = createdAt
        self.category = category
    }
}
