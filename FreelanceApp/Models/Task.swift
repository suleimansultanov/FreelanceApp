import Foundation

struct Task: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let startDate: String
    let endDate: String?
    let category: TaskCategory
    let status: TaskStatus
    let hasResponses: Bool
    let isRemote: Bool
    let price: Double
    let ownerId: String?
    let ownerUsername: String?
    let authorName: String?
    let description: String?
    let location: String?
    let createDate: String?
    let proposalsCount: Int?
    let isProposalSent: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case startDate
        case endDate
        case category
        case status
        case hasResponses
        case isRemote
        case price
        case ownerId
        case owner_id
        case createdBy
        case created_by
        case userId
        case user_id
        case ownerUsername
        case owner_username
        case authorName
        case author_name
        case description
        case location
        case createDate = "create_date"
        case proposalsCount
        case isProposalSent
        case createdByUsername
        case created_by_username
    }
    
    init(
        id: String,
        title: String,
        startDate: String,
        endDate: String?,
        category: TaskCategory,
        status: TaskStatus,
        hasResponses: Bool,
        isRemote: Bool,
        price: Double,
        ownerId: String? = nil,
        ownerUsername: String? = nil,
        authorName: String? = nil,
        description: String? = nil,
        location: String? = nil,
        createDate: String? = nil,
        proposalsCount: Int? = nil,
        isProposalSent: Bool? = nil
    ) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.category = category
        self.status = status
        self.hasResponses = hasResponses
        self.isRemote = isRemote
        self.price = price
        self.ownerId = ownerId
        self.ownerUsername = ownerUsername
        self.authorName = authorName
        self.description = description
        self.location = location
        self.createDate = createDate
        self.proposalsCount = proposalsCount
        self.isProposalSent = isProposalSent
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        startDate = try container.decode(String.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        category = try container.decode(TaskCategory.self, forKey: .category)
        status = try container.decode(TaskStatus.self, forKey: .status)
        hasResponses = try container.decode(Bool.self, forKey: .hasResponses)
        isRemote = try container.decode(Bool.self, forKey: .isRemote)
        price = try container.decode(Double.self, forKey: .price)
        
        let ownerIdCandidates: [CodingKeys] = [.ownerId, .owner_id, .createdBy, .created_by, .userId, .user_id]
        var decodedOwnerId: String? = nil
        for key in ownerIdCandidates {
            if let value = try container.decodeIfPresent(String.self, forKey: key) {
                decodedOwnerId = value
                break
            }
        }
        ownerId = decodedOwnerId
        
        let ownerUsernameCandidates: [CodingKeys] = [.ownerUsername, .owner_username, .createdByUsername, .created_by_username]
        var decodedOwnerUsername: String? = nil
        for key in ownerUsernameCandidates {
            if let value = try container.decodeIfPresent(String.self, forKey: key) {
                decodedOwnerUsername = value
                break
            }
        }
        ownerUsername = decodedOwnerUsername
        
        let authorNameCandidates: [CodingKeys] = [.authorName, .author_name]
        var decodedAuthorName: String? = nil
        for key in authorNameCandidates {
            if let value = try container.decodeIfPresent(String.self, forKey: key) {
                decodedAuthorName = value
                break
            }
        }
        authorName = decodedAuthorName
        
        description = try container.decodeIfPresent(String.self, forKey: .description)
        location = try container.decodeIfPresent(String.self, forKey: .location)
        createDate = try container.decodeIfPresent(String.self, forKey: .createDate)
        proposalsCount = try container.decodeIfPresent(Int.self, forKey: .proposalsCount)
        isProposalSent = try container.decodeIfPresent(Bool.self, forKey: .isProposalSent)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encode(category, forKey: .category)
        try container.encode(status, forKey: .status)
        try container.encode(hasResponses, forKey: .hasResponses)
        try container.encode(isRemote, forKey: .isRemote)
        try container.encode(price, forKey: .price)
        try container.encodeIfPresent(ownerId, forKey: .ownerId)
        try container.encodeIfPresent(ownerUsername, forKey: .ownerUsername)
        try container.encodeIfPresent(authorName, forKey: .authorName)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(location, forKey: .location)
        try container.encodeIfPresent(createDate, forKey: .createDate)
        try container.encodeIfPresent(proposalsCount, forKey: .proposalsCount)
        try container.encodeIfPresent(isProposalSent, forKey: .isProposalSent)
    }
    
    var formattedPrice: String {
        return "\(Int(price)) ₽"
    }
    
    var formattedDate: String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "dd MMM"
        
        if let date = inputFormatter.date(from: startDate) {
            return outputFormatter.string(from: date)
        }
        return startDate
    }
    
    var displayOwnerName: String? {
        if let author = authorName, !author.isEmpty {
            return author
        }
        
        if let username = ownerUsername, !username.isEmpty {
            return username
        }
        
        if let id = ownerId, !id.isEmpty {
            return id
        }
        
        return nil
    }
}

enum TaskCategory: String, Codable {
    case delivery = "delivery"
    case cleaning = "cleaning"
    case writing = "writing"
    case design = "design"
    case education = "education"
    case other = "other"
    
    var icon: String {
        switch self {
        case .delivery: return "wrench.fill"
        case .cleaning: return "paintbrush.fill"
        case .writing: return "laptopcomputer"
        case .design: return "paintbrush.fill"
        case .education: return "book.fill"
        case .other: return "circle.fill"
        }
    }
    
    var displayName: String {
        switch self {
        case .delivery: return "Ремонт"
        case .cleaning: return "Уборка"
        case .writing: return "Разработка"
        case .design: return "Дизайн"
        case .education: return "Обучение"
        case .other: return "Разное"
        }
    }
}

enum TaskStatus: String, Codable {
    case open
    case inProgress
    case completed
    case cancelled
    
    var displayName: String {
        switch self {
        case .open: return "Открыто"
        case .inProgress: return "В работе"
        case .completed: return "Завершено"
        case .cancelled: return "Отменено"
        }
    }
}
