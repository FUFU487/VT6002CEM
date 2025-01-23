import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

struct ProfileView: View {
    @State private var userName: String = "Loading..."
    @State private var userEmail: String = "Loading email..."
    @State private var userPhone: String = "Loading phone..."
    @State private var isEditing: Bool = false
    @EnvironmentObject var appState: AppState // 用於切換視圖的環境變量

    var body: some View {
        VStack(spacing: 20) {
            // Profile Picture
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .foregroundColor(.blue)

            // User Name
            if isEditing {
                TextField("Enter your name", text: $userName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
            } else {
                Text(userName)
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }

            Divider()

            // Contact Information
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(.gray)
                    Text("Email: ")
                        .fontWeight(.semibold)
                    Spacer()
                    Text(userEmail)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.gray) // Indicate that this field is not editable
                }
                .padding(.vertical, 5)

                HStack {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.gray)
                    if isEditing {
                        TextField("Enter your phone", text: $userPhone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    } else {
                        Text("Phone: ")
                            .fontWeight(.semibold)
                        Spacer()
                        Text(userPhone)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding(.vertical, 5)
            }
            .padding(.horizontal)

            Divider()

            // Settings and Actions
            VStack(spacing: 20) {
                if isEditing {
                    Button(action: {
                        saveUserData()
                        isEditing = false
                    }) {
                        Text("Save Changes")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        isEditing = false
                    }) {
                        Text("Cancel")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        isEditing = true
                    }) {
                        Text("Edit Profile")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(10)
                    }

                    Button(action: {
                        logOut()
                    }) {
                        Text("Log Out")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
        .onAppear {
            fetchUserData()
        }
    }

    private func fetchUserData() {
        let db = Firestore.firestore()
        let userId = "3Q2fUsnHJHNeP5adRhxR2nx8GMI3" // 預設使用的用戶 ID

        db.collection("User Profile").document(userId).getDocument { snapshot, error in
            if let error = error {
                print("Error fetching user data: \(error.localizedDescription)")
                return
            }

            guard let data = snapshot?.data() else {
                print("No user data found")
                return
            }

            self.userName = data["name"] as? String ?? "Unknown Name"
            self.userEmail = data["email"] as? String ?? "No email available"
            self.userPhone = data["phone"] as? String ?? "No phone available"
        }
    }

    private func saveUserData() {
        let db = Firestore.firestore()
        let userId = "3Q2fUsnHJHNeP5adRhxR2nx8GMI3" // 預設使用的用戶 ID

        let userData: [String: Any] = [
            "name": userName,
            "email": userEmail,
            "phone": userPhone
        ]

        db.collection("User Profile").document(userId).setData(userData) { error in
            if let error = error {
                print("Error saving user data: \(error.localizedDescription)")
            } else {
                print("User data successfully saved.")
            }
        }
    }

    private func logOut() {
        do {
            try Auth.auth().signOut()
            appState.isLoggedIn = false // 將應用狀態切換為未登錄
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView().environmentObject(AppState())
        }
    }
}

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = true
}
