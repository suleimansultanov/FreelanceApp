import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isShowingSignUp = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    // Logo and Title
                    VStack(spacing: 20) {
                        Image(systemName: "briefcase.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(Color.theme.primary)
                        
                        Text("FreelanceHub")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(Color.theme.primary)
                        
                        Text("Find work or hire talent")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 50)
                    
                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("Enter your email", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        // Password Field
                        VStack(alignment: .leading) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            SecureField("Enter your password", text: $password)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        // Forgot Password
                        Button("Forgot Password?") {
                            // Handle forgot password
                        }
                        .font(.subheadline)
                        .foregroundColor(Color.theme.primary)
                        
                        // Login Button
                        Button(action: handleLogin) {
                            Text("Log In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.theme.primary)
                                .cornerRadius(10)
                        }
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                            Text("OR")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(.secondary.opacity(0.3))
                        }
                        
                        // Sign Up Button
                        Button(action: { isShowingSignUp = true }) {
                            Text("Create an Account")
                                .font(.headline)
                                .foregroundColor(Color.theme.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.theme.primary.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .background(Color.theme.background)
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $isShowingSignUp) {
                SignUpView(isAuthenticated: $isAuthenticated)
            }
        }
    }
    
    private func handleLogin() {
        // Here you would typically validate the input and make an API call
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields"
            showingAlert = true
            return
        }
        
        // For demo purposes, we'll just check for a valid email format
        guard email.contains("@") else {
            alertMessage = "Please enter a valid email address"
            showingAlert = true
            return
        }
        
        // Simulate successful login
        isAuthenticated = true
    }
}

struct SignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var name = ""
    @State private var isFreelancer = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Binding var isAuthenticated: Bool
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("Full Name", text: $name)
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    SecureField("Password", text: $password)
                    SecureField("Confirm Password", text: $confirmPassword)
                }
                
                Section {
                    Toggle("I'm a Freelancer", isOn: $isFreelancer)
                }
                
                Section {
                    Button(action: handleSignUp) {
                        Text("Create Account")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(Color.theme.primary)
                    }
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func handleSignUp() {
        // Validate input
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            alertMessage = "Please fill in all fields"
            showingAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showingAlert = true
            return
        }
        
        // Simulate successful signup
        isAuthenticated = true
        dismiss()
    }
}

#Preview {
    LoginView(isAuthenticated: .constant(false))
}
