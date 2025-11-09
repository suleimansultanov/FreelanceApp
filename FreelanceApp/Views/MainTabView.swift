import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @StateObject private var taskViewModel: TaskViewModel
    @StateObject private var myTasksViewModel: MyTasksViewModel
    @State private var selectedTab = 0
    
    init() {
        let placeholderAuth = AuthViewModel()
        _taskViewModel = StateObject(wrappedValue: TaskViewModel(authViewModel: placeholderAuth))
        _myTasksViewModel = StateObject(wrappedValue: MyTasksViewModel(authViewModel: placeholderAuth))
    }
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                TabView(selection: $selectedTab) {
                    TasksView(viewModel: taskViewModel)
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Задания")
                        }
                        .tag(0)
                    
                    MessagesView(authViewModel: authViewModel)
                        .tabItem {
                            Image(systemName: "message")
                            Text("Сообщения")
                        }
                        .tag(1)
                    
                    NotificationsView(viewModel: myTasksViewModel)
                        .tabItem {
                            Image(systemName: "bell")
                            Text("Отклики")
                        }
                        .tag(2)
                    
                    ProfileView()
                        .tabItem {
                            Image(systemName: "person")
                            Text("Профиль")
                        }
                        .tag(3)
                    
                    ContractsListView(viewModel: ContractsViewModel(authViewModel: authViewModel))
                        .tabItem {
                            Image(systemName: "doc.plaintext")
                            Text("Контракты")
                        }
                        .tag(4)
                }
            } else {
                LoginView()
            }
        }
        .onAppear {
            // Update TaskViewModel with the current AuthViewModel
            taskViewModel.updateAuthViewModel(authViewModel)
            myTasksViewModel.updateAuthViewModel(authViewModel)
        }
        .onChange(of: authViewModel.currentUserId) { _ in
            taskViewModel.updateAuthViewModel(authViewModel)
            myTasksViewModel.updateAuthViewModel(authViewModel)
            taskViewModel.filterTasks(searchText: taskViewModel.searchText)
        }
        .onChange(of: authViewModel.currentUsername) { _ in
            taskViewModel.updateAuthViewModel(authViewModel)
            myTasksViewModel.updateAuthViewModel(authViewModel)
            taskViewModel.filterTasks(searchText: taskViewModel.searchText)
        }
    }
}

// Placeholder views for tabs that haven't been implemented yet

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
