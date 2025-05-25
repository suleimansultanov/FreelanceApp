import Foundation

struct User: Identifiable, Codable {
    let id: UUID
    var name: String
    var email: String
    var profileImage: String?
    var bio: String
    var isFreelancer: Bool
    var skills: [String]
    var hourlyRate: Double?
    var rating: Double
    var completedProjects: Int
    
    init(id: UUID = UUID(), name: String, email: String, profileImage: String? = nil, bio: String = "",
         isFreelancer: Bool = false, skills: [String] = [], hourlyRate: Double? = nil,
         rating: Double = 0.0, completedProjects: Int = 0) {
        self.id = id
        self.name = name
        self.email = email
        self.profileImage = profileImage
        self.bio = bio
        self.isFreelancer = isFreelancer
        self.skills = skills
        self.hourlyRate = hourlyRate
        self.rating = rating
        self.completedProjects = completedProjects
    }
}

extension User {
    static var preview: User {
        User(
            name: "Suleiman Sultanov",
            email: "suleiman@example.com",
            profileImage: nil,
            bio: "Mobile and AI developer with over 5 years of experience in building SwiftUI apps and machine learning models.",
            isFreelancer: true,
            skills: ["Swift", "SwiftUI", "CoreML", "Firebase"],
            hourlyRate: 50,
            rating: 4.9,
            completedProjects: 42
        )
    }
}

