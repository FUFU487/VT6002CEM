// Import necessary frameworks
import SwiftUI
import Firebase
import FirebaseAuth


struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoginMode: Bool = true
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: 30) {
            // Toggle between Login and Register
            Picker(selection: $isLoginMode, label: Text("Mode")) {
                Text("Login").tag(true)
                Text("Register").tag(false)
            }
            .pickerStyle(SegmentedPickerStyle())

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

            // Error Message Display
            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding()
            }

            // Submit Button
            Button(action: {
                isLoading = true
                handleAction()
            }) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text(isLoginMode ? "Login" : "Register")
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                }
            }
            .background(Color.blue)
            .cornerRadius(8)
            .disabled(email.isEmpty || password.isEmpty || isLoading)

            Spacer()
        }
        .padding()
        .navigationTitle(isLoginMode ? "Login" : "Register")
    }

    private func handleAction() {
        errorMessage = nil // Clear previous error

        guard email.contains("@") && email.contains("."), password.count >= 6 else {
            errorMessage = "Please enter a valid email and a password with at least 6 characters."
            isLoading = false
            return
        }

        if isLoginMode {
            loginUser()
        } else {
            registerUser()
        }
    }

    private func loginUser() {
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

    private func registerUser() {
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
                loginUser() // Automatically log in after registration
            }
        }
    }
}


#Preview {
    LoginView()
}
