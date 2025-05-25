import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let sender: User
    let content: String
    let timestamp: Date
    let isRead: Bool
}

struct MessagesView: View {
    @State private var searchText = ""
    
    // Sample data
    let conversations: [Message] = [
        Message(
            sender: .preview,
            content: "Hi! I'm interested in your iOS development services...",
            timestamp: Date().addingTimeInterval(-3600),
            isRead: false
        ),
        Message(
            sender: User(
                name: "Sarah Smith",
                email: "sarah@example.com",
                bio: "UI/UX Designer",
                isFreelancer: true,
                skills: ["UI/UX", "Figma", "Sketch"],
                rating: 4.9,
                completedProjects: 45
            ),
            content: "Thank you for your proposal! I've reviewed it and...",
            timestamp: Date().addingTimeInterval(-7200),
            isRead: true
        )
    ]
    
    var body: some View {
        NavigationView {
            List {
                ForEach(conversations) { message in
                    MessageRow(message: message)
                }
            }
            .navigationTitle("Messages")
            .searchable(text: $searchText, prompt: "Search messages...")
        }
    }
}

struct MessageRow: View {
    let message: Message
    
    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: URL(string: message.sender.profileImage ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Image(systemName: "person.circle.fill")
                    .foregroundColor(.secondary)
            }
            .frame(width: 50, height: 50)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.sender.name)
                        .font(.headline)
                    
                    Spacer()
                    
                    Text(timeAgo(from: message.timestamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Text(message.content)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if !message.isRead {
                        Circle()
                            .fill(Color.theme.primary)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    func timeAgo(from date: Date) -> String {
        let seconds = -date.timeIntervalSinceNow
        let minutes = Int(seconds / 60)
        let hours = Int(seconds / 3600)
        let days = Int(seconds / 86400)
        
        if seconds < 60 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes)m ago"
        } else if hours < 24 {
            return "\(hours)h ago"
        } else {
            return "\(days)d ago"
        }
    }
}

#Preview {
    MessagesView()
}
