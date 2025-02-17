// Import necessary frameworks
import SwiftUI
import Firebase
import FirebaseAuth
import LocalAuthentication

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    @State private var isShowingRegisterView: Bool = false
    @State private var isShowingForgotPasswordAlert: Bool = false
    @State private var isLoggedIn: Bool = false

    var body: some View {
        if isLoggedIn {
            ContentView()
        } else {
            NavigationView {
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

                    // Error Message Display
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    // Login and Face ID Buttons
                    HStack(spacing: 16) {
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

                        Button(action: {
                            authenticateWithBiometrics { success in
                                if success {
                                    print("Face ID Authentication Successful")
                                    isLoggedIn = true
                                } else {
                                    errorMessage = "Face ID Authentication Failed"
                                }
                            }
                        }) {
                            Image(systemName: "faceid")
                                .font(.title)
                                .foregroundColor(.blue) // 修改 logo 颜色为蓝色
                                .padding(12)
                                .background(Color(UIColor.systemGray6)) // 修改背景为米白色
                                .cornerRadius(9)
                        }
                    }

                    // Forgot Password Link
                    Button(action: {
                        isShowingForgotPasswordAlert = true
                    }) {
                        Text("Forgot Password?")
                            .foregroundColor(.blue)
                    }
                    .alert(isPresented: $isShowingForgotPasswordAlert) {
                        Alert(
                            title: Text("Forgot Password"),
                            message: Text("Please remember your password."),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                    Divider()

                    // Register Button
                    NavigationLink(destination: RegisterView(onRegisterComplete: {
                        isShowingRegisterView = false // 返回到登录页面
                    }), isActive: $isShowingRegisterView) {
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
                isLoggedIn = true
            }
        }
    }

    private func authenticateWithBiometrics(completion: @escaping (Bool) -> Void) {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Log in with Face ID or Touch ID"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, authenticationError in
                DispatchQueue.main.async {
                    completion(success)
                }
            }
        } else {
            print("Biometric authentication not available")
            completion(false)
        }
    }
}

struct RegisterView: View {
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false
    var onRegisterComplete: (() -> Void)? // 添加回调函数

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
                .textContentType(.password)
                .disableAutocorrection(true)

            // Confirm Password Input
            SecureField("Confirm Password", text: $confirmPassword)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)
                .textContentType(.password)
                .disableAutocorrection(true)

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
                onRegisterComplete?() // 注册成功后调用回调函数
            }
        }
    }
}

#Preview {
    LoginView()
}
