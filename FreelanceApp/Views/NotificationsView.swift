import SwiftUI
import Combine

final class MyTasksViewModel: ObservableObject {
    @Published var myTasks: [Task] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private var cancellables = Set<AnyCancellable>()
    private(set) var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func updateAuthViewModel(_ newAuthViewModel: AuthViewModel) {
        self.authViewModel = newAuthViewModel
        loadMyTasks()
    }
    
    func loadMyTasks() {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            error = "Authentication required. Please log in."
            myTasks = []
            return
        }
        
        print("🔐 [MyTasksViewModel] Using Authorization header for /tasks/me/ -> \(authHeader)")
        
        isLoading = true
        error = nil
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.myTasks,
            authHeader: authHeader
        ) { [weak self] (result: Result<[Task], NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let tasks):
                self.myTasks = tasks
            case .failure(let error):
                self.error = error.message
                self.myTasks = []
            }
        }
    }
}

struct NotificationsView: View {
    @ObservedObject var viewModel: MyTasksViewModel
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Загружаем ваши задания...")
                            .foregroundColor(.gray)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.error {
                    errorView(message: error)
                } else if viewModel.myTasks.isEmpty {
                    emptyStateView
                } else {
                    List {
                        ForEach(viewModel.myTasks) { task in
                            NavigationLink(destination: ProposalsListView(task: task, authViewModel: viewModel.authViewModel)) {
                                MyTaskCell(task: task)
                            }
                            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        viewModel.loadMyTasks()
                    }
                }
            }
            .navigationTitle("Мои задания")
            .background(Color(UIColor.systemGroupedBackground))
        }
        .onAppear {
            if viewModel.myTasks.isEmpty {
                viewModel.loadMyTasks()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            Text("Вы еще не создали ни одного задания")
                .font(.headline)
                .foregroundColor(.gray)
            Text("Создайте первое задание, чтобы увидеть его здесь.")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            Text(message)
                .multilineTextAlignment(.center)
                .foregroundColor(.red)
            Button("Повторить") {
                viewModel.loadMyTasks()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct MyTaskCell: View {
    let task: Task
    
    private var formattedCreateDate: String {
        guard let createDate = task.createDate else { return "" }
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFraction.date(from: createDate) {
            let output = DateFormatter()
            output.dateFormat = "dd.MM.yy"
            return output.string(from: date)
        }
        let formatterWithoutFraction = ISO8601DateFormatter()
        formatterWithoutFraction.formatOptions = [.withInternetDateTime]
        if let date = formatterWithoutFraction.date(from: createDate) {
            let output = DateFormatter()
            output.dateFormat = "dd.MM.yy"
            return output.string(from: date)
        }
        return createDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: task.category.icon)
                    .foregroundColor(.theme.primary)
                    .frame(width: 32, height: 32)
                    .background(Color.theme.primary.opacity(0.12))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Text(task.status.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(task.status == .open ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                    .foregroundColor(task.status == .open ? .green : .gray)
                    .cornerRadius(8)
            }
            
            HStack {
                if let location = task.location, !location.isEmpty {
                    Label(location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if task.proposalsCount ?? 0 > 0 {
                    Label("\(task.proposalsCount ?? 0)", systemImage: "person.3.fill")
                        .font(.caption)
                        .foregroundColor(.theme.primary)
                }
            }
            
            HStack {
                Label(task.formattedDate, systemImage: "calendar")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                if !formattedCreateDate.isEmpty {
                    Label(formattedCreateDate, systemImage: "clock")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Text(task.formattedPrice)
                    .font(.headline)
                    .foregroundColor(.theme.primary)
            }
        }
        .padding(.vertical, 8)
    }
}

#if !os(macOS)
struct Contract: Identifiable, Decodable {
    let id: String
    let taskId: String?
    let freelancerId: String?
    let hirerId: String?
    let amount: Double?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    let notes: String?
    let isContractAccepted: Bool?
    let freelancerName: String?
    let hirerName: String?
    
    var formattedDate: String {
        guard let createdAt else { return "" }
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFraction.date(from: createdAt) {
            return Contract.displayFormatter.string(from: date)
        }
        let formatterWithoutFraction = ISO8601DateFormatter()
        formatterWithoutFraction.formatOptions = [.withInternetDateTime]
        if let date = formatterWithoutFraction.date(from: createdAt) {
            return Contract.displayFormatter.string(from: date)
        }
        return createdAt
    }
    
    static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        return formatter
    }()
}

struct Proposal: Identifiable, Decodable {
    let id: String
    let taskId: String
    let senderId: String
    let senderName: String
    let coverLetter: String
    let createdAt: String
    let isContractOffered: Bool?
    
    var formattedDate: String {
        let formatterWithFraction = ISO8601DateFormatter()
        formatterWithFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatterWithFraction.date(from: createdAt) {
            let output = DateFormatter()
            output.dateFormat = "dd.MM.yyyy HH:mm"
            return output.string(from: date)
        }
        let formatterWithoutFraction = ISO8601DateFormatter()
        formatterWithoutFraction.formatOptions = [.withInternetDateTime]
        if let date = formatterWithoutFraction.date(from: createdAt) {
            let output = DateFormatter()
            output.dateFormat = "dd.MM.yyyy HH:mm"
            return output.string(from: date)
        }
        return createdAt
    }
}

final class ProposalsViewModel: ObservableObject {
    @Published var proposals: [Proposal] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let authViewModel: AuthViewModel
    private let taskId: String
    
    var authViewModelAccess: AuthViewModel { authViewModel }
    
    init(taskId: String, authViewModel: AuthViewModel) {
        self.taskId = taskId
        self.authViewModel = authViewModel
    }
    
    func loadProposals() {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            error = "Authentication required. Please log in."
            proposals = []
            return
        }
        
        let endpoint = Config.API.Endpoints.tasks + "\(taskId)/proposals"
        
        isLoading = true
        error = nil
        
        NetworkManager.shared.request(
            endpoint: endpoint,
            authHeader: authHeader
        ) { [weak self] (result: Result<[Proposal], NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let proposals):
                self.proposals = proposals
            case .failure(let error):
                self.error = error.message
                self.proposals = []
            }
        }
    }
    
    func proposeContract(taskId: String, freelancerId: String, hirerId: String, amount: Double, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            completion(.failure(.customError("Authentication required. Please log in.")))
            return
        }
        
        let body: [String: Any] = [
            "taskId": taskId,
            "freelancerId": freelancerId,
            "hirerId": hirerId,
            "amount": amount
        ]
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.contracts,
            method: .post,
            body: body,
            authHeader: authHeader
        ) { (result: Result<Contract, NetworkError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

final class ContractsViewModel: ObservableObject {
    @Published var contracts: [Contract] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let authViewModel: AuthViewModel
    
    var authViewModelReference: AuthViewModel { authViewModel }
    
    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    func loadContracts() {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            error = "Authentication required. Please log in."
            contracts = []
            return
        }
        
        isLoading = true
        error = nil
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.myContracts,
            authHeader: authHeader
        ) { [weak self] (result: Result<[Contract], NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let contracts):
                self.contracts = contracts
            case .failure(let error):
                self.error = error.message
                self.contracts = []
            }
        }
    }
}

final class ContractDetailViewModel: ObservableObject {
    @Published var contract: Contract?
    @Published var isLoading = false
    @Published var error: String?
    
    private let authViewModel: AuthViewModel
    private let contractId: String
    
    var authViewModelAccess: AuthViewModel { authViewModel }
    
    init(contractId: String, authViewModel: AuthViewModel) {
        self.contractId = contractId
        self.authViewModel = authViewModel
    }
    
    func loadContract() {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            error = "Authentication required. Please log in."
            contract = nil
            return
        }
        
        isLoading = true
        error = nil
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.contractDetail(contractId),
            authHeader: authHeader
        ) { [weak self] (result: Result<Contract, NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let contract):
                self.contract = contract
            case .failure(let error):
                self.error = error.message
                self.contract = nil
            }
        }
    }
    
    func acceptContract(completion: @escaping (Result<Contract, NetworkError>) -> Void) {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            completion(.failure(.customError("Authentication required. Please log in.")))
            return
        }
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.contractAccept(contractId),
            method: .post,
            authHeader: authHeader
        ) { [weak self] (result: Result<Contract, NetworkError>) in
            guard let self = self else { return }
            switch result {
            case .success(let contract):
                DispatchQueue.main.async {
                    self.contract = contract
                }
                completion(.success(contract))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

struct ProposalsListView: View {
    let task: Task
    @StateObject private var viewModel: ProposalsViewModel
    @State private var selectedProposal: Proposal?
    @State private var inviteAmount: String = ""
    @State private var inviteError: String?
    @State private var isInviting = false
    @State private var showingInviteSheet = false
    @State private var navigateToContracts = false
    
    init(task: Task, authViewModel: AuthViewModel) {
        self.task = task
        _viewModel = StateObject(wrappedValue: ProposalsViewModel(taskId: task.id, authViewModel: authViewModel))
    }
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(task.title)
                        .font(.headline)
                    if let description = task.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text(task.formattedPrice)
                            .font(.headline)
                            .foregroundColor(.theme.primary)
                        Spacer()
                        if let proposalsCount = task.proposalsCount {
                            Label("\(proposalsCount)", systemImage: "person.3.fill")
                                .font(.caption)
                                .foregroundColor(.theme.primary)
                        }
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section(header: Text("Отклики")) {
                if viewModel.isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else if let error = viewModel.error {
                    VStack(spacing: 12) {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                        Button("Повторить") {
                            viewModel.loadProposals()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical, 16)
                } else if viewModel.proposals.isEmpty {
                    Text("Откликов пока нет.")
                        .foregroundColor(.gray)
                        .padding(.vertical, 16)
                } else {
                    ForEach(viewModel.proposals) { proposal in
                        VStack(alignment: .leading, spacing: 8) {
                            NavigationLink(destination: ProposalDetailView(userId: proposal.senderId, authViewModel: viewModel.authViewModelAccess)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Text(proposal.senderName)
                                            .font(.headline)
                                        Spacer()
                                        Text(proposal.formattedDate)
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Text(proposal.coverLetter)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                }
                            }
                            
                            if proposal.isContractOffered == true {
                                Text("Контракт предложен")
                                    .font(.subheadline)
                                    .foregroundColor(.green)
                                    .padding(8)
                                    .background(Color.green.opacity(0.1))
                                    .cornerRadius(8)
                            } else {
                                Button {
                                    selectedProposal = proposal
                                    inviteAmount = ""
                                    inviteError = nil
                                    showingInviteSheet = true
                                } label: {
                                    Text("Предложить работу")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.theme.primary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .navigationTitle("Отклики")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadProposals()
        }
        .refreshable {
            viewModel.loadProposals()
        }
        .background(
            NavigationLink(
                destination: ContractsListView(viewModel: ContractsViewModel(authViewModel: viewModel.authViewModelAccess)),
                isActive: $navigateToContracts
            ) { EmptyView() }
        )
        .sheet(isPresented: $showingInviteSheet) {
            NavigationView {
                Form {
                    Section("Сумма предложения") {
                        TextField("Сумма, ₽", text: $inviteAmount)
                            .keyboardType(.decimalPad)
                    }
                    
                    if let inviteError = inviteError {
                        Section {
                            Text(inviteError)
                                .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Предложить работу")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Отмена") {
                            showingInviteSheet = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button(isInviting ? "Отправка..." : "Отправить") {
                            sendContractInvite()
                        }
                        .disabled(isInviting)
                    }
                }
            }
        }
    }
    
    private func sendContractInvite() {
        guard let proposal = selectedProposal else { return }
        guard let hirerId = viewModel.authViewModelAccess.currentUserId else {
            inviteError = "Не удалось определить заказчика"
            return
        }
        
        let amountValue = Double(inviteAmount.replacingOccurrences(of: ",", with: ".")) ?? 0
        isInviting = true
        inviteError = nil
        
        viewModel.proposeContract(taskId: task.id, freelancerId: proposal.senderId, hirerId: hirerId, amount: amountValue) { result in
            DispatchQueue.main.async {
                isInviting = false
                switch result {
                case .success:
                    showingInviteSheet = false
                    navigateToContracts = true
                case .failure(let error):
                    inviteError = error.message
                }
            }
        }
    }
}

struct ContractsListView: View {
    @StateObject private var viewModel: ContractsViewModel
    @State private var selectedCategory: ContractsCategory = .new
    
    enum ContractsCategory: String, CaseIterable, Identifiable {
        case new = "Новые"
        case sent = "Отправленные"
        case current = "Текущие"
        
        var id: String { rawValue }
    }
    
    init(viewModel: ContractsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Категория", selection: $selectedCategory) {
                    ForEach(ContractsCategory.allCases) { category in
                        Text(category.rawValue).tag(category)
                    }
                }
                .pickerStyle(.segmented)
                .padding([.horizontal, .top])
                
                List {
                    if viewModel.isLoading {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else if let error = viewModel.error {
                        VStack(spacing: 12) {
                            Text(error)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                            Button("Повторить") {
                                viewModel.loadContracts()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 16)
                    } else {
                        let contracts = filteredContracts
                        if contracts.isEmpty {
                            Text(emptyStateMessage)
                                .foregroundColor(.gray)
                                .padding(.vertical, 16)
                        } else {
                            ForEach(contracts) { contract in
                                NavigationLink(destination: ContractDetailView(contractId: contract.id, authViewModel: viewModel.authViewModelReference, onContractUpdated: {
                                    viewModel.loadContracts()
                                })) {
                                    ContractRow(contract: contract)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
                .refreshable {
                    viewModel.loadContracts()
                }
            }
            .navigationTitle("Контракты")
        }
        .onAppear {
            viewModel.loadContracts()
        }
    }
    
    private var filteredContracts: [Contract] {
        guard let currentUserId = viewModel.authViewModelReference.currentUserId else {
            return []
        }
        let normalizedContracts = viewModel.contracts
        switch selectedCategory {
        case .sent:
            return normalizedContracts.filter { contract in
                contract.hirerId == currentUserId
            }
        case .new:
            return normalizedContracts.filter { contract in
                contract.freelancerId == currentUserId && (contract.isContractAccepted ?? false) == false
            }
        case .current:
            return normalizedContracts.filter { contract in
                (contract.freelancerId == currentUserId) && (contract.isContractAccepted ?? false)
            }
        }
    }
    
    private var emptyStateMessage: String {
        switch selectedCategory {
        case .new:
            return "Новых контрактов нет"
        case .sent:
            return "Отправленных контрактов нет"
        case .current:
            return "Текущих контрактов нет"
        }
    }
    
    private func isPendingStatus(_ status: String?) -> Bool {
        guard let status = status?.lowercased() else { return true }
        return ["pending", "new", "offered", "waiting", "created"].contains(status)
    }
    
    private func isApprovedStatus(_ status: String?) -> Bool {
        guard let status = status?.lowercased() else { return false }
        return ["approved", "accepted", "in_progress", "active", "current"].contains(status)
    }
}

private struct ContractRow: View {
    let contract: Contract
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Контракт #\(String(contract.id.prefix(6)))")
                    .font(.headline)
                Spacer()
                Text(contract.formattedDate)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            if let amount = contract.amount {
                Text("Сумма: \(amount, specifier: "%.2f") ₽")
                    .foregroundColor(.theme.primary)
            }
            if let status = contract.status {
                Text("Статус: \(status)")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

struct ContractDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: ContractDetailViewModel
    private let onContractUpdated: (() -> Void)?
    @State private var isAccepting = false
    @State private var acceptError: String?
    
    init(contractId: String, authViewModel: AuthViewModel, onContractUpdated: (() -> Void)? = nil) {
        self.onContractUpdated = onContractUpdated
        _viewModel = StateObject(wrappedValue: ContractDetailViewModel(contractId: contractId, authViewModel: authViewModel))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Загружаем контракт...")
                        .foregroundColor(.gray)
                }
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.system(size: 40))
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                    Button("Повторить") {
                        viewModel.loadContract()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let contract = viewModel.contract {
                List {
                    Section("Общие сведения") {
                        DetailRow(label: "ID", value: contract.id)
                        DetailRow(label: "Дата", value: contract.formattedDate)
                        if let status = contract.status {
                            DetailRow(label: "Статус", value: status)
                        }
                    }
                    
                    Section("Участники") {
                        if let hirerName = contract.hirerName, !hirerName.isEmpty {
                            DetailRow(label: "Заказчик", value: hirerName)
                        } else if let hirer = contract.hirerId {
                            DetailRow(label: "Заказчик", value: hirer)
                        }
                        if let freelancerName = contract.freelancerName, !freelancerName.isEmpty {
                            DetailRow(label: "Исполнитель", value: freelancerName)
                        } else if let freelancer = contract.freelancerId {
                            DetailRow(label: "Исполнитель", value: freelancer)
                        }
                    }
                    
                    Section("Финансы") {
                        if let amount = contract.amount {
                            DetailRow(label: "Сумма", value: String(format: "%.2f ₽", amount))
                        }
                    }
                    
                    if let notes = contract.notes, !notes.isEmpty {
                        Section("Заметки") {
                            Text(notes)
                                .font(.body)
                        }
                    }
                    
                    if canAcceptContract {
                        Section {
                            if let acceptError {
                                Text(acceptError)
                                    .foregroundColor(.red)
                            }
                            Button(action: handleAccept) {
                                if isAccepting {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                } else {
                                    Text("Принять контракт")
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .buttonStyle(.borderedProminent)
                            .disabled(isAccepting)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            } else {
                Text("Контракт не найден")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Детали контракта")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadContract()
        }
    }
    
    private var canAcceptContract: Bool {
        guard let contract = viewModel.contract,
              let currentUserId = viewModel.authViewModelAccess.currentUserId else {
            return false
        }
        guard contract.freelancerId == currentUserId else { return false }
        if contract.isContractAccepted == true {
            return false
        }
        let status = contract.status?.lowercased() ?? "pending"
        let pendingStatuses = ["pending", "new", "offered", "waiting", "created"]
        return pendingStatuses.contains(status)
    }
    
    private func handleAccept() {
        isAccepting = true
        acceptError = nil
        viewModel.acceptContract { result in
            DispatchQueue.main.async {
                isAccepting = false
                switch result {
                case .success:
                    onContractUpdated?()
                    dismiss()
                case .failure(let error):
                    acceptError = error.message
                }
            }
        }
    }
}

private struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
    }
}

struct UserInfoResponse: Decodable {
    let name: String
    let tasksCompleted: Int
    let rating: Double?
}

struct UserFeedbackReview: Identifiable, Decodable {
    private let fallbackId = UUID().uuidString
    let reviewId: String?
    let reviewerName: String?
    let rating: Int?
    let reviewContent: String?
    let commentContent: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case reviewId = "id"
        case reviewerName
        case reviewerUsername
        case userName
        case rating
        case reviewContent
        case commentContent
        case createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reviewId = try container.decodeIfPresent(String.self, forKey: .reviewId)
        if let explicitName = try container.decodeIfPresent(String.self, forKey: .reviewerName) {
            reviewerName = explicitName
        } else if let username = try container.decodeIfPresent(String.self, forKey: .reviewerUsername) {
            reviewerName = username
        } else {
            reviewerName = try container.decodeIfPresent(String.self, forKey: .userName)
        }
        if let intRating = try container.decodeIfPresent(Int.self, forKey: .rating) {
            rating = intRating
        } else if let doubleRating = try container.decodeIfPresent(Double.self, forKey: .rating) {
            rating = Int(round(doubleRating))
        } else if let stringRating = try container.decodeIfPresent(String.self, forKey: .rating),
                  let parsed = Int(stringRating) {
            rating = parsed
        } else {
            rating = nil
        }
        reviewContent = try container.decodeIfPresent(String.self, forKey: .reviewContent)
        commentContent = try container.decodeIfPresent(String.self, forKey: .commentContent)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
    }
    
    var id: String { reviewId ?? fallbackId }
    
    var displayRating: Int {
        max(0, min(rating ?? 0, 5))
    }
}

final class ProposalDetailViewModel: ObservableObject {
    @Published var userInfo: UserInfoResponse?
    @Published var isLoading = false
    @Published var error: String?
    @Published var reviews: [UserFeedbackReview] = []
    @Published var isReviewsLoading = false
    @Published var reviewsError: String?
    
    private let userId: String
    private let authViewModel: AuthViewModel
    
    init(userId: String, authViewModel: AuthViewModel) {
        self.userId = userId
        self.authViewModel = authViewModel
    }
    
    func loadUserInfo() {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            error = "Authentication required. Please log in."
            userInfo = nil
            reviews = []
            reviewsError = "Authentication required. Please log in."
            return
        }
        
        isLoading = true
        error = nil
        loadUserReviews(authHeader: authHeader)
        
        let endpoint = Config.API.Endpoints.userInfo + "?userId=\(userId)"
        NetworkManager.shared.request(
            endpoint: endpoint,
            authHeader: authHeader
        ) { [weak self] (result: Result<UserInfoResponse, NetworkError>) in
            guard let self = self else { return }
            self.isLoading = false
            
            switch result {
            case .success(let info):
                self.userInfo = info
            case .failure(let error):
                self.error = error.message
                self.userInfo = nil
            }
        }
    }
    
    private func loadUserReviews(authHeader: String) {
        isReviewsLoading = true
        reviewsError = nil
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.feedbackForUser(userId),
            authHeader: authHeader
        ) { [weak self] (result: Result<[UserFeedbackReview], NetworkError>) in
            guard let self = self else { return }
            self.isReviewsLoading = false
            switch result {
            case .success(let reviews):
                self.reviews = reviews
            case .failure(let error):
                self.reviewsError = error.message
                self.reviews = []
            }
        }
    }
    
    func reloadReviews() {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            reviewsError = "Authentication required. Please log in."
            reviews = []
            isReviewsLoading = false
            return
        }
        loadUserReviews(authHeader: authHeader)
    }
}

struct ProposalDetailView: View {
    let userId: String
    let authViewModel: AuthViewModel
    @StateObject private var viewModel: ProposalDetailViewModel
    @State private var isMessageSheetPresented = false
    @State private var sendMessageSuccess = false
    @State private var isFeedbackSheetPresented = false
    @State private var sendFeedbackSuccess = false
    
    init(userId: String, authViewModel: AuthViewModel) {
        self.userId = userId
        self.authViewModel = authViewModel
        _viewModel = StateObject(wrappedValue: ProposalDetailViewModel(userId: userId, authViewModel: authViewModel))
    }

    init(userId: UUID, authViewModel: AuthViewModel) {
        self.init(userId: userId.uuidString, authViewModel: authViewModel)
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Загружаем профиль...")
                        .foregroundColor(.gray)
                }
            } else if let error = viewModel.error {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.system(size: 40))
                    Text(error)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                    Button("Повторить") {
                        viewModel.loadUserInfo()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            } else if let info = viewModel.userInfo {
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.theme.primary)
                            Text(info.name)
                                .font(.title2)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(spacing: 12) {
                            HStack {
                                Label("Выполнено заданий", systemImage: "checkmark.circle")
                                Spacer()
                                Text("\(info.tasksCompleted)")
                            }
                            .font(.headline)
                            
                            HStack {
                                Label("Рейтинг", systemImage: "star.fill")
                                Spacer()
                                if let rating = info.rating {
                                    Text(String(format: "%.1f", rating))
                                } else {
                                    Text("Нет данных")
                                        .foregroundColor(.gray)
                                }
                            }
                            .font(.headline)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.theme.cardBackground)
                        .cornerRadius(16)
                        
                        Button("Написать сообщение") {
                            isMessageSheetPresented = true
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.theme.primary)
                        .frame(maxWidth: .infinity)
                        
                        Button("Оставить отзыв") {
                            isFeedbackSheetPresented = true
                        }
                        .buttonStyle(.bordered)
                        .tint(.theme.primary)
                        .frame(maxWidth: .infinity)
                        
                        Divider()
                            .padding(.vertical, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Отзывы")
                                .font(.title3)
                                .fontWeight(.semibold)
                            
                            if viewModel.isReviewsLoading {
                                HStack {
                                    ProgressView()
                                    Text("Загружаем отзывы...")
                                        .foregroundColor(.gray)
                                }
                            } else if let reviewsError = viewModel.reviewsError {
                                VStack(spacing: 8) {
                                    Text(reviewsError)
                                        .foregroundColor(.red)
                                        .multilineTextAlignment(.leading)
                                    Button("Повторить") {
                                        viewModel.loadUserInfo() // Changed from reloadReviews to loadUserInfo
                                    }
                                    .buttonStyle(.borderedProminent)
                                }
                            } else if viewModel.reviews.isEmpty {
                                Text("Отзывов пока нет")
                                    .foregroundColor(.gray)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(viewModel.reviews) { review in
                                        ReviewRow(review: review)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding()
                }
            } else {
                Text("Нет данных о пользователе.")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Профиль исполнителя")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.loadUserInfo()
        }
        .sheet(isPresented: $isMessageSheetPresented) {
            SendMessageView(recipientName: viewModel.userInfo?.name ?? "", onSend: { message, completion in
                sendMessage(message: message) { result in
                    switch result {
                    case .success:
                        sendMessageSuccess = true
                        completion(.success(()))
                        isMessageSheetPresented = false
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            })
        }
        .sheet(isPresented: $isFeedbackSheetPresented) {
            LeaveReviewView(rating: 5, onSubmit: { rating, reviewContent, commentContent, completion in
                sendFeedback(rating: rating, reviewContent: reviewContent, commentContent: commentContent) { result in
                    switch result {
                    case .success:
                        sendFeedbackSuccess = true
                        completion(.success(()))
                        isFeedbackSheetPresented = false
                        viewModel.reloadReviews()
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            })
        }
        .alert("Сообщение отправлено", isPresented: $sendMessageSuccess) {
            Button("OK", role: .cancel) { }
        }
        .alert("Отзыв отправлен", isPresented: $sendFeedbackSuccess) {
            Button("OK", role: .cancel) { }
        }
    }
    
    private func sendFeedback(rating: Int, reviewContent: String, commentContent: String, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            completion(.failure(.customError("Authentication required. Please log in.")))
            return
        }
        
        let body: [String: Any] = [
            "userId": userId,
            "rating": rating,
            "reviewContent": reviewContent,
            "commentContent": commentContent
        ]
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.feedback,
            method: .post,
            body: body,
            authHeader: authHeader
        ) { (result: Result<EmptyResponse, NetworkError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func sendMessage(message: String, completion: @escaping (Result<Void, NetworkError>) -> Void) {
        guard let authHeader = authViewModel.getAuthorizationHeader() else {
            completion(.failure(.customError("Authentication required. Please log in.")))
            return
        }
        
        let body: [String: Any] = [
            "userId": userId,
            "message": message
        ]
        
        NetworkManager.shared.request(
            endpoint: Config.API.Endpoints.chats,
            method: .post,
            body: body,
            authHeader: authHeader
        ) { (result: Result<EmptyResponse, NetworkError>) in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
}

struct SendMessageView: View {
    @Environment(\.dismiss) private var dismiss
    let recipientName: String
    var onSend: (String, @escaping (Result<Void, NetworkError>) -> Void) -> Void
    
    @State private var message: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Сообщение")
                    .font(.headline)
                
                TextEditor(text: $message)
                    .frame(minHeight: 200)
                    .padding(8)
                    .background(Color.theme.secondaryBackground)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2))
                    )
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                }
                
                Spacer()
                
                Button(action: submit) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        }
                        Text(isSubmitting ? "Отправка..." : "Отправить")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.theme.primary)
                .disabled(isSubmitting)
            }
            .padding()
            .navigationTitle(recipientName.isEmpty ? "Сообщение" : "Сообщение для \(recipientName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submit() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Пожалуйста, введите сообщение"
            return
        }
        
        errorMessage = nil
        isSubmitting = true
        
        onSend(trimmed) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.message
                }
            }
        }
    }
}

struct LeaveReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var ratingSelection: Int
    @State private var reviewContent: String = ""
    @State private var commentContent: String = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    let onSubmit: (Int, String, String, @escaping (Result<Void, NetworkError>) -> Void) -> Void
    
    init(rating: Int = 5, onSubmit: @escaping (Int, String, String, @escaping (Result<Void, NetworkError>) -> Void) -> Void) {
        _ratingSelection = State(initialValue: rating)
        self.onSubmit = onSubmit
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Оценка") {
                    Picker("Рейтинг", selection: $ratingSelection) {
                        ForEach(1...5, id: \.self) { value in
                            Text("\(value) ⭐️").tag(value)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Отзыв") {
                    TextEditor(text: $reviewContent)
                        .frame(minHeight: 120)
                }
                
                Section("Комментарий") {
                    TextEditor(text: $commentContent)
                        .frame(minHeight: 120)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button(action: submit) {
                        HStack {
                            if isSubmitting {
                                ProgressView()
                            }
                            Text(isSubmitting ? "Отправка..." : "Отправить отзыв")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("Оставить отзыв")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func submit() {
        let trimmedReview = reviewContent.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedComment = commentContent.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedReview.isEmpty else {
            errorMessage = "Пожалуйста, заполните поле Отзыв"
            return
        }
        guard !trimmedComment.isEmpty else {
            errorMessage = "Пожалуйста, заполните поле Комментарий"
            return
        }
        errorMessage = nil
        isSubmitting = true
        onSubmit(ratingSelection, trimmedReview, trimmedComment) { result in
            DispatchQueue.main.async {
                isSubmitting = false
                switch result {
                case .success:
                    dismiss()
                case .failure(let error):
                    errorMessage = error.message
                }
            }
        }
    }
}

private struct ReviewRow: View {
    let review: UserFeedbackReview
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 2) {
                    ForEach(0..<5, id: \.self) { index in
                        Image(systemName: index < review.displayRating ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                Text(reviewerDisplayName)
                    .font(.headline)
                Spacer()
            }
            if let reviewText = review.reviewContent, !reviewText.isEmpty {
                Text(reviewText)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }
            if let commentText = review.commentContent, !commentText.isEmpty {
                Text(commentText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var reviewerDisplayName: String {
        if let name = review.reviewerName, !name.isEmpty {
            return "Отзыв от \(name)"
        }
        return "Отзыв"
    }
}
#endif

#Preview {
    NotificationsView(viewModel: MyTasksViewModel(authViewModel: AuthViewModel()))
}
