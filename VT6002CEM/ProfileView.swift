//
//  ProfileView.swift
//  VT6002CEM
//
//  Created by Vincent on 23/1/2025.
//


import SwiftUI

struct ProfileView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Profile Picture
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            // User Name
            Text("Your Name")
                .font(.title)
                .fontWeight(.bold)

            // User Bio
            Text("This is a brief bio about the user. You can add more details here if needed.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()

            // Contact Information
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.gray)
                    Text("user@example.com")
                }

                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.gray)
                    Text("+123 456 7890")
                }

                HStack {
                    Image(systemName: "location")
                        .foregroundColor(.gray)
                    Text("City, Country")
                }
            }
            .padding(.horizontal)

            Divider()

            // Settings and Actions
            VStack(spacing: 15) {
                Button(action: {
                    // Edit profile action
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
                    // Log out action
                }) {
                    Text("Log Out")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("Profile")
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ProfileView()
        }
    }
}
