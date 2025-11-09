import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: TaskDetailViewModel

    private let onDeleteSuccess: (() -> Void)?

    init(taskId: String, authViewModel: AuthViewModel, onDeleteSuccess: (() -> Void)? = nil) {
        _viewModel = StateObject(wrappedValue: TaskDetailViewModel(taskId: taskId, authViewModel: authViewModel))
        self.onDeleteSuccess = onDeleteSuccess
    }

    var body: some View {
        content
            .navigationTitle("Детали задания")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.theme.background.ignoresSafeArea())
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            VStack(spacing: 12) {
                ProgressView()
                Text("Загружаем задание...")
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = viewModel.error {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text(error)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.red)
                Button("Назад") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let task = viewModel.task {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header(for: task)
                    priceSection(for: task)
                    detailsSection
                    tagsSection(for: task)
                }
                .padding()
            }
        } else {
            VStack(spacing: 12) {
                Text("Не удалось загрузить данные задания.")
                    .foregroundColor(.gray)
                Button("Назад") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func header(for task: Task) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: task.category.icon)
                .font(.largeTitle)
                .foregroundColor(.theme.primary)
                .frame(width: 60, height: 60)
                .background(Color.theme.primary.opacity(0.12))
                .cornerRadius(16)

            VStack(alignment: .leading, spacing: 8) {
                Text(task.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.theme.text)
                Text(task.category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.theme.mutedText)
                if let createDate = viewModel.createDate {
                    Text("Создано: \(viewModel.formatCreateDate(createDate))")
                        .font(.caption)
                        .foregroundColor(.theme.mutedText)
                }
            }
            Spacer()
        }
    }

    private func priceSection(for task: Task) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Стоимость")
                .font(.headline)
            Text(task.formattedPrice)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.theme.primary)

            HStack {
                Text("Статус: \(task.status.displayName)")
                    .font(.subheadline)
                Spacer()
                Text(task.isRemote ? "Удаленно" : "На месте")
                    .font(.subheadline)
                    .foregroundColor(task.isRemote ? .theme.secondary : .theme.text)
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
    }

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let description = viewModel.taskDescription, !description.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Описание")
                        .font(.headline)
                    Text(description)
                        .foregroundColor(.theme.text)
                }
            }

            if let location = viewModel.taskLocation, !location.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Местоположение")
                        .font(.headline)
                    Text(location)
                        .foregroundColor(.theme.text)
                }
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
    }

    private func tagsSection(for task: Task) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Дополнительно")
                .font(.headline)

            HStack(spacing: 8) {
                TagView(icon: "calendar", text: task.formattedDate, color: .theme.primary)
                if let endDate = task.endDate, !endDate.isEmpty {
                    TagView(icon: "calendar.badge.clock", text: endDate, color: .theme.secondary)
                }
            }
        }
        .padding()
        .background(Color.theme.cardBackground)
        .cornerRadius(16)
    }
}

private struct TagView: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            Text(text)
        }
        .font(.caption)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .cornerRadius(12)
    }
}
