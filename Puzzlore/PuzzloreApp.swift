//
//  PuzzloreApp.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Set all windows to have a dark background
        for window in windowScene.windows {
            window.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0) // Deep blue/black
        }
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        guard let windowScene = scene as? UIWindowScene else { return }
        for window in windowScene.windows {
            window.backgroundColor = UIColor(red: 0.05, green: 0.05, blue: 0.15, alpha: 1.0)
        }
    }
}

@main
struct PuzzloreApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var progressManager = ProgressManager.shared
    @State private var showSplash = true
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .opacity(showSplash || showOnboarding ? 0 : 1)

                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                }

                if showOnboarding {
                    OnboardingView(onComplete: {
                        progressManager.completeOnboarding()
                        withAnimation(.easeOut(duration: 0.5)) {
                            showOnboarding = false
                        }
                    })
                    .transition(.opacity)
                }
            }
            .onAppear {
                // Show splash for 3 seconds, then check for onboarding
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation(.easeOut(duration: 0.5)) {
                        showSplash = false

                        // Show onboarding if first launch
                        if !progressManager.hasCompletedOnboarding {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeIn(duration: 0.5)) {
                                    showOnboarding = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
