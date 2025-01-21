//
//  ContentView.swift
//  VT6002CEM
//
//  Created by Vincent on 14/1/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // Home Tab
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // My Files Tab
            MyFilesView()
                .tabItem {
                    Image(systemName: "folder.fill")
                    Text("My Files")
                }
            
            // Upload Tab
            UploadView()
                .tabItem {
                    Image(systemName: "plus.circle.fill")
                    Text("Upload")
                }
            
            // Notifications Tab
            NotificationsView()
                .tabItem {
                    Image(systemName: "bell.fill")
                    Text("Notifications")
                }
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}

// Sample Views for each Tab
struct HomeView: View {
    var body: some View {
        Text("Home View")
            .font(.largeTitle)
            .foregroundColor(.purple)
    }
}

struct MyFilesView: View {
    var body: some View {
        Text("My Files View")
            .font(.largeTitle)
            .foregroundColor(.blue)
    }
}


struct NotificationsView: View {
    var body: some View {
        Text("Notifications View")
            .font(.largeTitle)
            .foregroundColor(.orange)
    }
}

struct ProfileView: View {
    var body: some View {
        Text("Profile View")
            .font(.largeTitle)
            .foregroundColor(.green)
    }
}

// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
