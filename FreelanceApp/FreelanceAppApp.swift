//
//  FreelanceAppApp.swift
//  FreelanceApp
//
//  Created by Suleiman Sultanov on 22/5/25.
//

import SwiftUI

@main
struct FreelanceAppApp: App {
    @State private var isAuthenticated = false
    var body: some Scene {
        WindowGroup {
            if isAuthenticated {
                MainTabView()
            } else {
                LoginView(isAuthenticated: $isAuthenticated)
            }
        }
    }
}
