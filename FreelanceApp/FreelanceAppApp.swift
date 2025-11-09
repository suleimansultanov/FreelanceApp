//
//  FreelanceAppApp.swift
//  FreelanceApp
//
//  Created by Suleiman Sultanov on 22/5/25.
//

import SwiftUI

@main
struct FreelanceAppApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(authViewModel)
            .preferredColorScheme(.light)
        }
    }
}
