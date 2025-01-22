// Import necessary frameworks
import SwiftUI
import Firebase
import FirebaseAuth

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var isShowingRegisterView: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                // Email Input
                TextField("Email or Phone Number", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                // Password Input
                SecureField("Password", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                // Error Message Display
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                // Login Button
                Button(action: {
                    isLoading = true
                    loginUser()
                }) {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Login")
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                }
                .background(Color.blue)
                .cornerRadius(8)
                .disabled(email.isEmpty || password.isEmpty || isLoading)

                // Forgot Password Link
                Button(action: {
                    // Handle forgot password action
                }) {
                    Text("Forgot Password?")
                        .foregroundColor(.blue)
                }

                Divider()

                // Register Button
                NavigationLink(destination: RegisterView(), isActive: $isShowingRegisterView) {
                    Button(action: {
                        isShowingRegisterView = true
                    }) {
                        Text("Create New Account").foregroundColor(.white)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(Color.green)
                            .cornerRadius(8)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Login")
        }
    }

    private func loginUser() {
        errorMessage = nil
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error as NSError? {
                switch AuthErrorCode(rawValue: error.code) {
                case .invalidEmail:
                    errorMessage = "Invalid email address."
                case .wrongPassword:
                    errorMessage = "Incorrect password."
                case .userNotFound:
                    errorMessage = "No user found with this email."
                default:
                    errorMessage = error.localizedDescription
                }
            } else {
                print("Successfully logged in with user: \(result?.user.uid ?? "")")
            }
        }
    }
}

struct RegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            // Email Input
            TextField("Email", text: $email)
                .autocapitalization(.none)
                .keyboardType(.emailAddress)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            // Password Input
            SecureField("Password", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            // Confirm Password Input
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            // Error Message Display
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            // Register Button
            Button(action: {
                isLoading = true
                registerUser()
            }) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Register")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            }
            .background(Color.green)
            .cornerRadius(8)

            Spacer()
        }
        .padding()
        .navigationTitle("Register")
    }

    private func registerUser() {
        errorMessage = nil

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            isLoading = false
            return
        }

        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            isLoading = false
            if let error = error as NSError? {
                switch AuthErrorCode(rawValue: error.code) {
                case .emailAlreadyInUse:
                    errorMessage = "This email is already registered."
                case .invalidEmail:
                    errorMessage = "Invalid email address."
                default:
                    errorMessage = error.localizedDescription
                }
            } else {
                print("Successfully registered user: \(result?.user.uid ?? "")")
            }
        }
    }
}

#Preview {
    LoginView()
}
