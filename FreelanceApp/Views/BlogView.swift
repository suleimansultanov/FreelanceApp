import SwiftUI

struct BlogPost: Identifiable {
    let id = UUID()
    let title: String
    let imageURL: URL?
    let description: String
    let date: Date
}

struct BlogView: View {
    @State private var blogPosts: [BlogPost] = [
        BlogPost(
            title: "Решили убраться? Получайте за это подарки!",
            imageURL: URL(string: "https://ailimits.netlify.app/static/media/mainBg.f209c429818ec5750200.jpeg"),
            description: "Нагрис и YouDo проводят акцию и раздают чистящие средства в подарок",
            date: Date()
        ),
        BlogPost(
            title: "Самые необычные задания июня. Выпуск 73",
            imageURL: URL(string: "https://ailimits.netlify.app/static/media/feelblock.bdb1066913adb54e64e7.jpg"),
            description: "Подборка интересных заданий за прошедший месяц",
            date: Date().addingTimeInterval(-7 * 24 * 3600)
        )
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(blogPosts) { post in
                        BlogPostCard(post: post)
                    }
                }
                .padding()
            }
            .navigationTitle("Блог YouDo")
            .background(Color.theme.background)
        }
    }
}

struct BlogPostCard: View {
    let post: BlogPost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let imageURL = post.imageURL {
                AsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.theme.secondaryBackground)
                }
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)
            } else {
                Rectangle()
                    .fill(Color.theme.secondaryBackground)
                    .frame(height: 200)
                    .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(post.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.theme.text)

                Text(post.description)
                    .font(.subheadline)
                    .foregroundColor(.theme.mutedText)

                Text(formatDate(post.date))
                    .font(.caption)
                    .foregroundColor(.theme.mutedText)
            }
            .padding(.horizontal, 4)
        }
        .background(Color.theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.theme.shadowColor, radius: 5, x: 0, y: 2)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}

#Preview {
    BlogView()
}


