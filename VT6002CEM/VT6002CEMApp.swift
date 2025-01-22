//
//  VT6002CEMApp.swift
//  VT6002CEM
//
//  Created by Vincent on 14/1/2025.
//

import SwiftUI
import FirebaseCore

@main
struct VT6002CEMApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            LoginView()
        }
    }
}
