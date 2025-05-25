import SwiftUI

struct ProfileView: View {
    @State private var user: User = .preview
    @State private var isEditingProfile = false
    @State private var showingImagePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 16) {
                        AsyncImage(url: URL(string: user.profileImage ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.theme.primary, lineWidth: 3)
                        )
                        .onTapGesture {
                            showingImagePicker = true
                        }
                        
                        VStack(spacing: 8) {
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(user.isFreelancer ? "Freelancer" : "Client")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            if user.isFreelancer {
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.yellow)
                                    Text(String(format: "%.1f", user.rating))
                                    Text("(\(user.completedProjects) projects)")
                                        .foregroundColor(.secondary)
                                }
                                .font(.subheadline)
                            }
                        }
                    }
                    .padding()
                    .background(Color.theme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.theme.shadowColor, radius: 8, x: 0, y: 4)
                    
                    // Bio Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About")
                            .font(.headline)
                        
                        Text(user.bio)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.theme.cardBackground)
                    .cornerRadius(16)
                    .shadow(color: Color.theme.shadowColor, radius: 8, x: 0, y: 4)
                    
                    if user.isFreelancer {
                        // Skills Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Skills")
                                .font(.headline)
                            
                            FlowLayout(spacing: 8) {
                                ForEach(user.skills, id: \.self) { skill in
                                    Text(skill)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.theme.accent.opacity(0.1))
                                        .foregroundColor(Color.theme.accent)
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.theme.cardBackground)
                        .cornerRadius(16)
                        .shadow(color: Color.theme.shadowColor, radius: 8, x: 0, y: 4)
                        
                        // Rate Section
                        if let hourlyRate = user.hourlyRate {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Hourly Rate")
                                    .font(.headline)
                                
                                Text("$\(Int(hourlyRate))/hour")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.theme.primary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(Color.theme.cardBackground)
                            .cornerRadius(16)
                            .shadow(color: Color.theme.shadowColor, radius: 8, x: 0, y: 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                Button("Edit") {
                    isEditingProfile = true
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView(user: $user)
            }
        }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var width: CGFloat = 0
        var height: CGFloat = 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var maxHeight: CGFloat = 0
        
        for size in sizes {
            if x + size.width > (proposal.width ?? .infinity) {
                x = 0
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
            width = max(width, x)
            height = y + maxHeight
        }
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        
        var x = bounds.minX
        var y = bounds.minY
        var maxHeight: CGFloat = 0
        
        for (index, size) in sizes.enumerated() {
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += maxHeight + spacing
                maxHeight = 0
            }
            
            subviews[index].place(
                at: CGPoint(x: x, y: y),
                proposal: ProposedViewSize(size)
            )
            
            x += size.width + spacing
            maxHeight = max(maxHeight, size.height)
        }
    }
}

struct EditProfileView: View {
    @Binding var user: User
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var hourlyRate: Double = 0
    @State private var skills: [String] = []
    @State private var newSkill: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Basic Information")) {
                    TextField("Name", text: $name)
                    TextEditor(text: $bio)
                        .frame(height: 100)
                }
                
                if user.isFreelancer {
                    Section(header: Text("Professional Details")) {
                        HStack {
                            Text("$")
                            TextField("Hourly Rate", value: $hourlyRate, format: .number)
                                .keyboardType(.decimalPad)
                            Text("/hour")
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Skills")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            ForEach(skills, id: \.self) { skill in
                                HStack {
                                    Text(skill)
                                    Spacer()
                                    Button(action: {
                                        skills.removeAll { $0 == skill }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            HStack {
                                TextField("Add skill", text: $newSkill)
                                Button("Add") {
                                    if !newSkill.isEmpty {
                                        skills.append(newSkill)
                                        newSkill = ""
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
            .onAppear {
                // Load current user data
                name = user.name
                bio = user.bio
                hourlyRate = user.hourlyRate ?? 0
                skills = user.skills
            }
        }
    }
    
    private func saveChanges() {
        user.name = name
        user.bio = bio
        user.hourlyRate = hourlyRate
        user.skills = skills
    }
}

#Preview {
    ProfileView()
}
