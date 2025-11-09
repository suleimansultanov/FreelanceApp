import SwiftUI

struct TasksView: View {
    @ObservedObject var viewModel: TaskViewModel
    @State private var showingFilters = false
    @State private var showingCreateTask = false
    @State private var taskPendingDeletion: Task?

    var body: some View {
        NavigationView {
            content
                .navigationTitle("Задания")
                .navigationBarItems(
                    leading: Button(action: { }) {
                        Image(systemName: "line.horizontal.3")
                            .foregroundColor(.theme.text)
                    },
                    trailing: HStack {
                        Button(action: { showingFilters.toggle() }) {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.theme.text)
                        }

                        Button(action: { showingCreateTask.toggle() }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.theme.primary)
                        }
                    }
                )
        }
        .background(Color.theme.background)
        .sheet(isPresented: $showingCreateTask, onDismiss: {
            viewModel.loadTasks()
        }) {
            CreateTaskView()
        }
        .sheet(isPresented: $showingFilters) {
            TaskFilterSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            "Удалить задание?",
            isPresented: Binding(
                get: { taskPendingDeletion != nil },
                set: { if !$0 { taskPendingDeletion = nil } }
            ),
            presenting: taskPendingDeletion
        ) { task in
            Button("Удалить", role: .destructive) {
                viewModel.deleteTask(task)
                taskPendingDeletion = nil
            }
            Button("Отмена", role: .cancel) {
                taskPendingDeletion = nil
            }
        } message: { _ in
            Text("Вы уверены, что хотите удалить это задание? Это действие нельзя отменить.")
        }
    }

    private func refreshTasks() async {
        await MainActor.run {
            viewModel.loadTasks()
        }
    }
}

private extension TasksView {
    @ViewBuilder
    var content: some View {
        VStack(spacing: 0) {
            SearchBar(text: $viewModel.searchText)
                .padding()

            filterBar

            mainSection
        }
    }

    var filterBar: some View {
        HStack(spacing: 20) {
            FilterButton(title: "Все",
                         isSelected: viewModel.selectedFilter == .all) {
                viewModel.selectedFilter = .all
            }

            FilterButton(title: "Рекомендованные",
                         isSelected: viewModel.selectedFilter == .recommended) {
                viewModel.selectedFilter = .recommended
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    var mainSection: some View {
        if let error = viewModel.error {
            errorView(error)
        } else if viewModel.isLoading {
            loadingView
        } else if viewModel.filteredTasks.isEmpty {
            emptyStateView
        } else {
            tasksList
        }
    }

    func errorView(_ message: String) -> some View {
        VStack {
            Text(message)
                .foregroundColor(.red)
                .padding()

            Button("Повторить") {
                viewModel.loadTasks()
            }
            .foregroundColor(.theme.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var loadingView: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle())
            .scaleEffect(1.5)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            if !viewModel.searchText.isEmpty {
                Text("Ничего не найдено")
                    .font(.headline)
                    .foregroundColor(.gray)
                Text("Попробуйте изменить параметры поиска")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                Text("Нет доступных заданий")
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var tasksList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                if !viewModel.searchText.isEmpty {
                    HStack {
                        Text("Результаты поиска")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(viewModel.filteredTasks.count)")
                            .font(.subheadline)
                            .foregroundColor(.theme.primary)
                    }
                    .padding(.horizontal)
                }

                ForEach(viewModel.filteredTasks) { task in
                    NavigationLink(destination: TaskDetailView(
                        taskId: task.id,
                        authViewModel: viewModel.authViewModel,
                        onDeleteSuccess: { viewModel.removeTaskLocally(withId: task.id) }
                    )) {
                        taskRow(for: task)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await refreshTasks()
        }
    }

    func taskRow(for task: Task) -> some View {
        let isOwnedByCurrentUser = viewModel.isTaskOwnedByCurrentUser(task)

        return TaskCell(
            task: task,
            showDeleteButton: isOwnedByCurrentUser,
            isOwnedByCurrentUser: isOwnedByCurrentUser,
            isDeleting: viewModel.isDeleting(task: task),
            onDelete: {
                taskPendingDeletion = task
            }
        )
    }
}

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)

            TextField("Поиск по заданиям...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())

            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(8)
        .background(Color.theme.secondaryBackground)
        .cornerRadius(10)
    }
}

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(isSelected ? .white : Color.theme.text)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.theme.primary : Color.theme.secondaryBackground)
                .cornerRadius(20)
        }
    }
}

struct TaskCell: View {
    let task: Task
    var showDeleteButton: Bool = false
    var isOwnedByCurrentUser: Bool = false
    var isDeleting: Bool = false
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: task.category.icon)
                    .foregroundColor(.theme.primary)
                    .frame(width: 30, height: 30)
                    .background(Color.theme.primary.opacity(0.12))
                    .cornerRadius(8)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .foregroundColor(.theme.text)

                    if let ownerName = task.displayOwnerName {
                        HStack(spacing: 4) {
                            Image(systemName: "person.crop.circle")
                                .foregroundColor(.gray)
                            Text(isOwnedByCurrentUser ? "Вы" : ownerName)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }

                    Text(task.category.displayName)
                        .font(.subheadline)
                        .foregroundColor(.gray)
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

            Divider()

            footerSection
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(12)
        .shadow(color: Color.theme.shadowColor, radius: 5, x: 0, y: 2)
        .overlay(alignment: .topTrailing) {
            if showDeleteButton {
                Group {
                    if isDeleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .frame(width: 24, height: 24)
                    } else {
                        Button(action: { onDelete?() }) {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .padding(8)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                .padding(4)
            }
        }
    }

    @ViewBuilder
    private var footerSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 4) {
                    Image(systemName: "calendar")
                        .foregroundColor(.gray)
                    Text(task.formattedDate)
                }
                .font(.caption)
                .foregroundColor(.gray)

                Spacer()

                if let price = priceView {
                    price
                }
            }

            HStack(spacing: 8) {
                if task.isRemote {
                    TaskBadgeView(
                        icon: "house",
                        text: "Удаленно",
                        foregroundColor: .theme.secondary,
                        backgroundColor: Color.theme.secondary.opacity(0.15)
                    )
                }

                if !task.hasResponses {
                    TaskBadgeView(
                        icon: "person.fill.checkmark",
                        text: "Без откликов",
                        foregroundColor: .green,
                        backgroundColor: Color.green.opacity(0.1)
                    )
                }

                Spacer()
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if let ownerName = task.displayOwnerName {
                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle")
                    Text(isOwnedByCurrentUser ? "Вы" : ownerName)
                }
                .font(.caption2)
                .foregroundColor(.gray)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.theme.secondaryBackground)
                .clipShape(Capsule())
                .offset(y: 14)
            }
        }
    }

    private var priceView: Text? {
        guard task.price > 0 else { return nil }
        return Text(task.formattedPrice)
            .font(.headline)
            .foregroundColor(.theme.primary)
    }
}

private struct TaskBadgeView: View {
    let icon: String
    let text: String
    let foregroundColor: Color
    let backgroundColor: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(8)
    }
}

struct TaskFilterSheet: View {
    @ObservedObject var viewModel: TaskViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var minPriceText: String = ""
    @State private var maxPriceText: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Категория")) {
                    Picker("Категория", selection: Binding(
                        get: { viewModel.selectedCategory },
                        set: { viewModel.selectedCategory = $0; applyFilters() }
                    )) {
                        Text("Все").tag(TaskCategory?.none)

                        ForEach([TaskCategory.cleaning, .delivery, .writing, .design, .education, .other], id: \.rawValue) { category in
                            Text(category.displayName).tag(TaskCategory?.some(category))
                        }
                    }
                }

                Section(header: Text("Статус")) {
                    Picker("Статус", selection: Binding(
                        get: { viewModel.selectedStatus },
                        set: { viewModel.selectedStatus = $0; applyFilters() }
                    )) {
                        Text("Все").tag(TaskStatus?.none)
                        ForEach([TaskStatus.open, .inProgress, .completed, .cancelled], id: \.rawValue) { status in
                            Text(status.displayName).tag(TaskStatus?.some(status))
                        }
                    }
                }

                Section(header: Text("Цена")) {
                    TextField("Минимальная цена", text: Binding(
                        get: { minPriceText },
                        set: { minPriceText = $0; updatePriceFilters() }
                    ))
                    .keyboardType(.decimalPad)

                    TextField("Максимальная цена", text: Binding(
                        get: { maxPriceText },
                        set: { maxPriceText = $0; updatePriceFilters() }
                    ))
                    .keyboardType(.decimalPad)
                }

                Section {
                    Toggle("Только удаленная работа", isOn: Binding(
                        get: { viewModel.onlyRemote },
                        set: { viewModel.onlyRemote = $0; applyFilters() }
                    ))

                    Toggle("Скрыть задания с откликами", isOn: Binding(
                        get: { viewModel.hideWithResponses },
                        set: { viewModel.hideWithResponses = $0; applyFilters() }
                    ))
                }
            }
            .navigationTitle("Фильтры")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Сбросить") {
                        resetFilters()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Готово") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
            .onAppear {
                minPriceText = viewModel.minPrice.map { String(format: "%.0f", $0) } ?? ""
                maxPriceText = viewModel.maxPrice.map { String(format: "%.0f", $0) } ?? ""
            }
        }
    }

    private func updatePriceFilters() {
        if let value = Double(minPriceText.replacingOccurrences(of: ",", with: ".")) {
            viewModel.minPrice = value
        } else {
            viewModel.minPrice = nil
        }

        if let value = Double(maxPriceText.replacingOccurrences(of: ",", with: ".")) {
            viewModel.maxPrice = value
        } else {
            viewModel.maxPrice = nil
        }

        applyFilters()
    }

    private func applyFilters() {
        viewModel.filterTasks(searchText: viewModel.searchText)
    }

    private func resetFilters() {
        viewModel.selectedCategory = nil
        viewModel.selectedStatus = nil
        viewModel.minPrice = nil
        viewModel.maxPrice = nil
        viewModel.onlyRemote = false
        viewModel.hideWithResponses = false
        minPriceText = ""
        maxPriceText = ""
        applyFilters()
    }
}

#Preview {
    TasksView(viewModel: TaskViewModel(authViewModel: AuthViewModel()))
        .preferredColorScheme(.light)
}

