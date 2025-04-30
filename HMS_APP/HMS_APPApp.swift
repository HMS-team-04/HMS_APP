//
//  HMS_APPApp.swift
//  HMS_APP
//
//  Created by Prasanjit Panda on 30/04/25.
//

import SwiftUI
import FirebaseCore

@main
struct HMS_APPApp: App {
    init() {
        FirebaseApp.configure()
    }
    @StateObject private var authManager = AuthManager()
    
    func setupFirebase() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                SignUpScreen()
            }
            .environmentObject(authManager)
        }
    }
}

