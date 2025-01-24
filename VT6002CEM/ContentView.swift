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
            Home()
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
            
            
            // Profile Tab
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
        }
    }
}




// Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
