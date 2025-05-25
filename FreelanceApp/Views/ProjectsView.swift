import SwiftUI

struct ProjectsView: View {
    @State private var selectedFilter: ProjectStatus = .open
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        FilterPill(title: "Open", isSelected: selectedFilter == .open) {
                            selectedFilter = .open
                        }
                        FilterPill(title: "In Progress", isSelected: selectedFilter == .inProgress) {
                            selectedFilter = .inProgress
                        }
                        FilterPill(title: "Completed", isSelected: selectedFilter == .completed) {
                            selectedFilter = .completed
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                
                // Projects list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(0..<10) { _ in
                            ProjectCard(project: .preview)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Projects")
            .searchable(text: $searchText, prompt: "Search projects...")
        }
    }
}

struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.theme.primary : Color.theme.cardBackground)
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

struct ProjectCard: View {
    let project: Project
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(project.title)
                        .font(.headline)
                    Text(project.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("$\(Int(project.budget))")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.theme.primary)
            }
            
            Text(project.description)
                .font(.subheadline)
                .lineLimit(2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(project.requiredSkills, id: \.self) { skill in
                        Text(skill)
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.theme.accent.opacity(0.1))
                            .foregroundColor(Color.theme.accent)
                            .cornerRadius(12)
                    }
                }
            }
            
            if let deadline = project.deadline {
                HStack {
                    Image(systemName: "clock")
                    Text("Due \(deadline, style: .date)")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
        .shadow(color: Color.theme.shadowColor, radius: 8, x: 0, y: 4)
    }
}

// Preview helper
extension Project {
    static var preview: Project {
        Project(
            title: "iOS App Development",
            description: "Looking for an experienced iOS developer to create a social networking app with modern UI/UX design.",
            budget: 5000,
            deadline: Date().addingTimeInterval(86400 * 30),
            requiredSkills: ["Swift", "SwiftUI", "iOS", "Firebase"],
            clientId: UUID(),
            category: "Mobile Development"
        )
    }
}

#Preview {
    ProjectsView()
}
