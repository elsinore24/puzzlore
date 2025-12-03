//
//  SettingsView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/30/25.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var progressManager = ProgressManager.shared
    @State private var showResetAlert = false
    @State private var showResetOnboardingAlert = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var showOnboarding = false

    // Navigation callbacks
    var switchToPlayTab: () -> Void = {}
    var switchToMapTab: () -> Void = {}
    var switchToCollectionTab: () -> Void = {}

    // Local state for toggles (synced with ProgressManager)
    @State private var musicEnabled = true
    @State private var soundEnabled = true
    @State private var hapticsEnabled = true
    @State private var notificationsEnabled = false

    var body: some View {
        GeometryReader { geo in
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            let topInset = window?.safeAreaInsets.top ?? 59

            ZStack {
                // Background
                Constants.Colors.backgroundGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    header
                        .padding(.horizontal)
                        .padding(.top, topInset + 8)

                    // Settings content
                    ScrollView {
                        VStack(spacing: 16) {
                            // Audio & Feedback section
                            settingsSection {
                                settingsToggle(
                                    icon: "music.note",
                                    title: "Music",
                                    isOn: $musicEnabled
                                )

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                settingsToggle(
                                    icon: "speaker.wave.2.fill",
                                    title: "Sound",
                                    isOn: $soundEnabled
                                )

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                settingsToggle(
                                    icon: "iphone.radiowaves.left.and.right",
                                    title: "Haptics",
                                    isOn: $hapticsEnabled
                                )

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                settingsToggle(
                                    icon: "bell.fill",
                                    title: "Notifications",
                                    isOn: $notificationsEnabled
                                )
                            }

                            // Actions section
                            settingsSection {
                                settingsButton(
                                    title: "View Tutorial",
                                    color: Constants.Colors.gold
                                ) {
                                    showOnboarding = true
                                }

                                Divider()
                                    .background(Color.white.opacity(0.1))

                                settingsButton(
                                    title: "Support",
                                    color: Constants.Colors.purple
                                ) {
                                    // Open support email or webpage
                                    if let url = URL(string: "mailto:support@ndmlabs.com") {
                                        UIApplication.shared.open(url)
                                    }
                                }
                            }

                            // Danger zone section
                            settingsSection {
                                settingsButton(
                                    title: "Reset Progress",
                                    color: Color.red.opacity(0.8)
                                ) {
                                    showResetAlert = true
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 120)

                        // Footer with legal links
                        footer
                            .padding(.bottom, 40)
                    }

                    Spacer()

                    // Bottom navigation icons
                    bottomNavigation
                        .padding(.bottom, geo.safeAreaInsets.bottom + 20)
                }
            }
        }
        .ignoresSafeArea()
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            // Load current settings
            musicEnabled = progressManager.musicEnabled
            soundEnabled = progressManager.soundEnabled
            hapticsEnabled = progressManager.hapticsEnabled
            notificationsEnabled = progressManager.notificationsEnabled
        }
        .onChange(of: musicEnabled) { _, newValue in
            progressManager.musicEnabled = newValue
        }
        .onChange(of: soundEnabled) { _, newValue in
            progressManager.soundEnabled = newValue
        }
        .onChange(of: hapticsEnabled) { _, newValue in
            progressManager.hapticsEnabled = newValue
        }
        .onChange(of: notificationsEnabled) { _, newValue in
            progressManager.notificationsEnabled = newValue
        }
        .alert("Reset Progress?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                progressManager.resetProgress()
            }
        } message: {
            Text("This will reset all your progress and moonstones. This cannot be undone.")
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(onComplete: {
                showOnboarding = false
            })
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            // Spacer for alignment (no settings button needed - we're on settings)
            Color.clear.frame(width: 48, height: 48)

            Spacer()

            // Centered title
            Text("Settings")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            // Spacer for alignment
            Color.clear.frame(width: 48, height: 48)
        }
    }

    // MARK: - Bottom Navigation

    private var bottomNavigation: some View {
        HStack(spacing: 0) {
            bottomNavButton(icon: "house.fill", isSelected: false) {
                switchToPlayTab()
            }
            bottomNavButton(icon: "map.fill", isSelected: false) {
                switchToMapTab()
            }
            bottomNavButton(icon: "gift.fill", isSelected: false) {
                // Rewards or shop
            }
            bottomNavButton(icon: "book.fill", isSelected: false) {
                switchToCollectionTab()
            }
        }
        .padding(.horizontal, 40)
    }

    private func bottomNavButton(icon: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Constants.Colors.gold : Color.white.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundColor(isSelected ? Constants.Colors.gold : .white)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Settings Section

    private func settingsSection<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) {
            content()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Constants.Colors.deepBlue.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Settings Toggle

    private func settingsToggle(icon: String, title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(Constants.Colors.gold)
                .frame(width: 30)

            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(PuzzloreToggleStyle())
        }
        .padding(.vertical, 12)
    }

    // MARK: - Settings Button

    private func settingsButton(title: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule()
                        .fill(color)
                )
        }
        .padding(.vertical, 8)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 16) {
            HStack(spacing: 30) {
                Button {
                    showTermsOfService = true
                } label: {
                    Text("Terms of Service")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .underline()
                }

                Button {
                    showPrivacyPolicy = true
                } label: {
                    Text("Privacy Policy")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                        .underline()
                }
            }

            Text("Ver 1.0.0")
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.4))
        }
    }
}

// MARK: - Custom Toggle Style

struct PuzzloreToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            ZStack {
                Capsule()
                    .fill(configuration.isOn ? Constants.Colors.gold : Color.gray.opacity(0.4))
                    .frame(width: 51, height: 31)

                Circle()
                    .fill(Color.white)
                    .frame(width: 27, height: 27)
                    .offset(x: configuration.isOn ? 10 : -10)
                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isOn)
            .onTapGesture {
                configuration.isOn.toggle()
            }
        }
    }
}

#Preview {
    SettingsView()
}
