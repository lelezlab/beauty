//
//  beautyApp.swift
//  beauty
//
//  Created by 张丽媛 on 8/18/25.
//

import SwiftUI
import SwiftData
import UIKit
import AuthenticationServices
import AVFoundation
 

@main
struct beautyApp: App {
    // Temporarily remove SwiftData container to simplify preview/build

    @StateObject private var appState = AppState()
    @StateObject private var i18n = LocalizationManager.shared
    @StateObject private var results = ResultsStore()

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
            .environmentObject(results)
            .task {
                // 请求相机权限（真机首开无弹窗时主动触发）
                _ = await AVCaptureDevice.requestAccess(for: .video)
            }
        }
        .modelContainer(for: [BeautySession.self])
    }
}
