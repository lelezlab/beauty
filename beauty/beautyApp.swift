//
//  beautyApp.swift
//  beauty
//
//  Created by 张丽媛 on 8/18/25.
//

import SwiftUI
// import SwiftData
import UIKit
import AuthenticationServices
 

@main
struct beautyApp: App {
    // Temporarily remove SwiftData container to simplify preview/build

    @StateObject private var appState = AppState()
    @StateObject private var i18n = LocalizationManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if appState.isLoggedIn {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(appState)
            .environmentObject(i18n)
        }
    }
}
