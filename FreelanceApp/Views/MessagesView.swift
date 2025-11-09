import SwiftUI

struct Message: Identifiable {
    let id = UUID()
    let senderName: String
    let senderAvatar: URL?
    let lastMessage: String
    let date: Date
    let isRead: Bool
    let username: String?
}

struct MessagesView: View {
    @StateObject private var viewModel: MessagesViewModel
    @State private var searchText = ""
    
    init(authViewModel: AuthViewModel) {
        _viewModel = StateObject(wrappedValue: MessagesViewModel(authViewModel: authViewModel))
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                Color(.systemBackground)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    searchBar
                    
                    if viewModel.showDropdown {
                        UserSearchDropdown(
                            users: viewModel.searchResults,
                            onUserSelected: { user in
                                viewModel.selectUser(user)
                                hideKeyboard()
                            },
                            onDismiss: {
                                viewModel.dismissDropdown()
                                hideKeyboard()
                            }
                        )
                        .padding(.horizontal)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .zIndex(1)
                    }
                    
                    content
                        .zIndex(0)
                }
            }
            .navigationTitle("Сообщения")
            .navigationBarTitleDisplayMode(.large)
            .background(
                NavigationLink(
                    destination: destinationForSelectedUser,
                    isActive: Binding(
                        get: { viewModel.selectedUser != nil },
                        set: { if !$0 { viewModel.clearSelectedUser() } }
                    )
                ) {
                    EmptyView()
                }
            )
        }
    }
    
    private var destinationForSelectedUser: some View {
        Group {
            if let selectedUser = viewModel.selectedUser {
                ProposalDetailView(userId: selectedUser.id, authViewModel: viewModel.authViewModelReference)
            } else {
                EmptyView()
            }
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(
                "Поиск пользователей",
                text: Binding(
                    get: { viewModel.searchText },
                    set: { viewModel.searchText = $0 }
                )
            )
            .textFieldStyle(PlainTextFieldStyle())
            .autocapitalization(.none)
            .disableAutocorrection(true)
            
            if !viewModel.searchText.isEmpty {
                Button(action: {
                    viewModel.searchText = ""
                    hideKeyboard()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoadingChats {
            VStack(spacing: 12) {
                ProgressView()
                Text("Загружаем чаты...")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.error {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text(error)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red)
                Button("Повторить") {
                    viewModel.refreshChats()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.chats.isEmpty {
            VStack(spacing: 16) {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 50))
                    .foregroundColor(.gray)
                Text("Чаты не найдены")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Начните новый диалог, чтобы увидеть его здесь.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                ForEach(viewModel.chats) { chat in
                    NavigationLink(destination: ChatMessagesView(chat: chat, authViewModel: viewModel.authViewModelReference, currentUserId: viewModel.authViewModelReference.currentUserId, currentUsername: viewModel.currentUsername)) {
                        ChatRow(chat: chat, currentUsername: viewModel.currentUsername)
                    }
                    .listRowBackground(shouldHighlight(chat: chat) ? Color.theme.secondary.opacity(0.12) : Color.clear)
                }
            }
            .listStyle(PlainListStyle())
            .refreshable {
                viewModel.refreshChats()
            }
        }
    }
    
    private func shouldHighlight(chat: ChatSummary) -> Bool {
        guard let isViewed = chat.lastMessageIsViewed, let currentUsername = viewModel.currentUsername else {
            return false
        }
        return !isViewed && (chat.lastMessageSenderName ?? "") != currentUsername
    }
}

private struct ChatRow: View {
    let chat: ChatSummary
    let currentUsername: String?
    
    private var participantName: String {
        if let name = chat.participantName, !name.isEmpty {
            return name
        }
        if let sender = chat.lastMessageSenderName, sender != currentUsername {
            return sender
        }
        return "Собеседник"
    }
    
    private var lastMessageText: String {
        if let sender = chat.lastMessageSenderName, let message = chat.lastMessage, !message.isEmpty {
            let displaySender = sender == currentUsername ? "Вы" : sender
            return "\(displaySender): \(message)"
        }
        return chat.lastMessage ?? ""
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .frame(width: 48, height: 48)
                .foregroundColor(.theme.primary)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(participantName)
                    .font(.headline)
                    .foregroundColor(chat.lastMessageIsViewed == false && chat.lastMessageSenderName != currentUsername ? .theme.primary : .primary)
                
                Text(lastMessageText)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(chat.formattedDate)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct MessageCell: View {
    let message: Message
    
    var body: some View {
        HStack(spacing: 12) {
            if let avatarURL = message.senderAvatar {
                AsyncImage(url: avatarURL) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .foregroundColor(.gray)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(message.senderName)
                        .font(.headline)
                        .foregroundColor(message.isRead ? .primary : Color.theme.primary)
                    
                    if let username = message.username {
                        Text(username)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                if !message.lastMessage.isEmpty {
                    Text(message.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(formatDate(message.date))
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        return formatter.string(from: date)
    }
}

struct ChatMessagesView: View {
    let chat: ChatSummary
    let authViewModel: AuthViewModel
    let currentUserId: String?
    let currentUsername: String?
    @StateObject private var viewModel: ChatMessagesViewModel
    @State private var messageDraft: String = ""
    @State private var isSending = false
    @State private var sendError: String?
    
    init(chat: ChatSummary, authViewModel: AuthViewModel, currentUserId: String?, currentUsername: String?) {
        self.chat = chat
        self.authViewModel = authViewModel
        self.currentUserId = currentUserId
        self.currentUsername = currentUsername
        _viewModel = StateObject(wrappedValue: ChatMessagesViewModel(chatId: chat.id, authViewModel: authViewModel))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading {
                Spacer()
                ProgressView()
                Spacer()
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                    Button("Повторить") {
                        viewModel.loadMessages()
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                List {
                    ForEach(viewModel.messages) { message in
                        ChatMessageBubble(message: message, isCurrentUser: message.senderId == currentUserId, senderName: message.senderId == currentUserId ? (currentUsername ?? "Вы") : (chat.participantName ?? message.senderId))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(PlainListStyle())
                .refreshable {
                    viewModel.loadMessages()
                }
            }
            composer
        }
        .navigationTitle(chat.participantName ?? "Чат")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadMessages()
            markChatViewed()
        }
    }
    
    private var composer: some View {
        VStack(spacing: 8) {
            if let sendError = sendError {
                Text(sendError)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
            HStack(alignment: .bottom, spacing: 12) {
                TextField("Сообщение", text: $messageDraft, axis: .vertical)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding(10)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(12)
                    .lineLimit(1...4)
                
                Button(action: sendMessage) {
                    if isSending {
                        ProgressView()
                    } else {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.white)
                    }
                }
                .padding(10)
                .background(Color.theme.primary)
                .cornerRadius(10)
                .disabled(isSending || messageDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color.theme.cardBackground.shadow(color: Color.theme.shadowColor, radius: 4, x: 0, y: -2))
    }
    
    private func markChatViewed() {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            return
        }
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.markChatViewed(chat.id),
            method: .post,
            body: [:],
            authHeader: authHeader
        ) { (_: Result<EmptyResponse, NetworkError>) in
            // Fire-and-forget; we don't need to handle the result here.
        }
    }
    
    private func sendMessage() {
        let trimmed = messageDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard !isSending else { return }
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            sendError = "Authentication required. Please log in."
            return
        }
        
        isSending = true
        sendError = nil
        
        let body: [String: Any] = [
            "content": trimmed
        ]
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.sendChatMessage(chat.id),
            method: .post,
            body: body,
            authHeader: authHeader
        ) { (result: Result<ChatMessage, NetworkError>) in
            isSending = false
            switch result {
            case .success(let message):
                messageDraft = ""
                viewModel.appendMessage(message)
            case .failure(let error):
                sendError = error.message
            }
        }
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    let isCurrentUser: Bool
    let senderName: String
    
    private var formattedDate: String {
        message.formattedDate
    }
    
    var body: some View {
        HStack {
            if isCurrentUser { Spacer() }
            VStack(alignment: .leading, spacing: 4) {
                Text(senderName)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(message.content)
                    .padding(10)
                    .background(isCurrentUser ? Color.theme.primary.opacity(0.18) : Color.theme.secondaryBackground)
                    .foregroundColor(.primary)
                    .cornerRadius(12)
                Text(formattedDate)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            if !isCurrentUser { Spacer() }
        }
        .padding(.vertical, 4)
    }
}

struct ChatMessage: Identifiable, Decodable {
    let id: String
    let senderId: String
    let receiverId: String
    let content: String
    let timestamp: String
    let chatId: String
    let isViewed: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case content
        case timestamp
        case chatId
        case isViewed = "isViewed"
    }
    
    var date: Date? {
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFraction.date(from: timestamp) {
            return date
        }
        let formatterWithoutFraction = ISO8601DateFormatter()
        formatterWithoutFraction.formatOptions = [.withInternetDateTime]
        return formatterWithoutFraction.date(from: timestamp)
    }
    
    var formattedDate: String {
        guard let date = date else { return timestamp }
        let display = DateFormatter()
        display.dateFormat = "dd.MM.yyyy HH:mm"
        return display.string(from: date)
    }
}

final class ChatMessagesViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let chatId: String
    private let authViewModel: AuthViewModel
    
    init(chatId: String, authViewModel: AuthViewModel) {
        self.chatId = chatId
        self.authViewModel = authViewModel
    }
    
    func loadMessages() {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            error = "Authentication required. Please log in."
            messages = []
            return
        }
        
        isLoading = true
        error = nil
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.chatMessages(chatId),
            authHeader: authHeader
        ) { [weak self] (result: Result<[ChatMessage], NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let messages):
                self.messages = messages.sorted { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
            case .failure(let error):
                self.error = error.message
                self.messages = []
            }
        }
    }
    
    func appendMessage(_ message: ChatMessage) {
        messages.append(message)
        messages.sort { ($0.date ?? Date.distantPast) < ($1.date ?? Date.distantPast) }
    }
}

#Preview {
    MessagesView(authViewModel: AuthViewModel())
}
