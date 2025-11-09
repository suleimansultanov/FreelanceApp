import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showRegistration = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Login form section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Вход")
                        .font(.title2)
                        .fontWeight(.bold)
                    
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
                    
                    if let error = authViewModel.error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.top, 4)
                    }
                    
                    // Login button
                    Button(action: {
                        authViewModel.loginWithEmailAndPassword(email: username, password: password)
                    }) {
                        HStack {
                            if authViewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .padding(.trailing, 8)
                            }
                            Text("Войти")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.theme.primary)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(username.isEmpty || password.isEmpty || authViewModel.isLoading)
                    
                    // Registration button
                    Button(action: { showRegistration = true }) {
                        Text("Нет аккаунта? Зарегистрироваться")
                            .foregroundColor(Color.theme.secondary)
                    }
                    .padding(.top)
                }
                
                // Social login section
                VStack(spacing: 16) {
                    Text("Или войти через")
                        .font(.headline)
                    
                    HStack(spacing: 12) {
                        // Apple login button
                        SocialLoginButton(icon: "apple.logo", backgroundColor: .black) {
                            authViewModel.loginWithApple()
                        }
                        
                        // VK login button
                        SocialLoginButton(icon: "message.fill", backgroundColor: Color(red: 0.13, green: 0.44, blue: 0.76)) {
                            authViewModel.loginWithVK()
                        }
                        
                        // Google login button
                        SocialLoginButton(icon: "g.circle.fill", backgroundColor: Color.blue) {
                            authViewModel.loginWithGoogle()
                        }
                        
                        // More options button
                        SocialLoginButton(icon: "ellipsis", backgroundColor: Color(.systemGray4)) {
                            // Show more options
                        }
                    }
                }
                .padding(.top, 40)
                
                Spacer()
            }
            .padding()
            .navigationBarItems(leading: Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .foregroundColor(.gray)
            })
            .navigationBarTitleDisplayMode(.inline)
        }
        .sheet(isPresented: $showRegistration) {
            RegistrationView()
        }
    }
}

struct SocialLoginButton: View {
    let icon: String
    let backgroundColor: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 20))
                .frame(width: 44, height: 44)
                .background(backgroundColor)
                .cornerRadius(8)
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

