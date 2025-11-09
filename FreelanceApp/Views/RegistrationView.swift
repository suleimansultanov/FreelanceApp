import SwiftUI

struct RegistrationView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var localError: String?
    
    var passwordsMatch: Bool {
        return password == confirmPassword
    }
    
    var isFormValid: Bool {
        return !username.isEmpty && !password.isEmpty && !confirmPassword.isEmpty && passwordsMatch
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Регистрация")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 16) {
                        // Username field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Имя пользователя")
                                .foregroundColor(.gray)
                            
                            TextField("Введите имя пользователя", text: $username)
                                .autocapitalization(.none)
                                .autocorrectionDisabled(true)
                                .padding()
                                .background(Color.theme.secondaryBackground)
                                .cornerRadius(10)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Пароль")
                                .foregroundColor(.gray)
                            
                            HStack {
                                if showPassword {
                                    TextField("Введите пароль", text: $password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled(true)
                                } else {
                                    SecureField("Введите пароль", text: $password)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled(true)
                                }
                                
                                Button(action: { showPassword.toggle() }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.theme.secondaryBackground)
                            .cornerRadius(10)
                        }
                        
                        // Confirm Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Подтвердите пароль")
                                .foregroundColor(.gray)
                            
                            HStack {
                                if showConfirmPassword {
                                    TextField("Повторите пароль", text: $confirmPassword)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled(true)
                                } else {
                                    SecureField("Повторите пароль", text: $confirmPassword)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled(true)
                                }
                                
                                Button(action: { showConfirmPassword.toggle() }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding()
                            .background(Color.theme.secondaryBackground)
                            .cornerRadius(10)
                        }
                    }
                    
                    if !passwordsMatch && !confirmPassword.isEmpty {
                        Text("Пароли не совпадают")
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    if let error = authViewModel.error ?? localError {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
                    // Register button
                    Button(action: {
                        guard passwordsMatch else {
                            localError = "Пароли не совпадают"
                            return
                        }
                        authViewModel.register(username: username, password: password)
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text("Зарегистрироваться")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.theme.primary : Color.gray.opacity(0.4))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid || authViewModel.isLoading)
                    
                    // Login link
                    Button(action: { dismiss() }) {
                        Text("Уже есть аккаунт? Войти")
                            .foregroundColor(.theme.secondary)
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.theme.text)
            })
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AuthViewModel())
}
