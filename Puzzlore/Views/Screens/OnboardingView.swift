//
//  OnboardingView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/30/25.
//

import SwiftUI

struct OnboardingView: View {
    let onComplete: () -> Void

    @State private var showTutorial = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfService = false
    @State private var hasAcceptedTerms = false

    var body: some View {
        ZStack {
            // Background
            Constants.Colors.backgroundGradient
                .ignoresSafeArea()

            // Welcome + Terms page (first page)
            welcomeTermsPage
                .opacity(showTutorial ? 0 : 1)
                .offset(x: showTutorial ? -50 : 0)

            // How to Play page (second page)
            howToPlayPage
                .opacity(showTutorial ? 1 : 0)
                .offset(x: showTutorial ? 0 : 50)
        }
        .animation(.easeInOut(duration: 0.5), value: showTutorial)
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showTermsOfService) {
            TermsOfServiceView()
        }
    }

    // MARK: - Welcome + Terms Page (Combined)

    private var welcomeTermsPage: some View {
        VStack(spacing: 20) {
            Spacer()

            // App icon/logo area
            ZStack {
                Circle()
                    .fill(Constants.Colors.deepBlue.opacity(0.5))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 55))
                    .foregroundColor(Constants.Colors.gold)
            }
            .glow(color: Constants.Colors.gold, radius: 20)

            VStack(spacing: 8) {
                Text("Welcome to")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))

                Text("PUZZLORE")
                    .font(.system(size: 38, weight: .bold, design: .serif))
                    .foregroundColor(Constants.Colors.gold)
                    .glow(color: Constants.Colors.gold, radius: 10)

                Text("Rebus Puzzles")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Text("Solve visual word puzzles and\nunlock magical spirit companions")
                .font(.system(size: 15))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.top, 5)

            Spacer()

            // Terms section
            VStack(spacing: 16) {
                Text("To continue, please accept our terms")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)

                // Links to privacy policy and terms
                HStack(spacing: 20) {
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        Text("Privacy Policy")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Constants.Colors.starCyan)
                            .underline()
                    }

                    Button {
                        showTermsOfService = true
                    } label: {
                        Text("Terms of Service")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Constants.Colors.starCyan)
                            .underline()
                    }
                }

                // Accept toggle
                Button {
                    hasAcceptedTerms.toggle()
                } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(hasAcceptedTerms ? Constants.Colors.gold : Color.white.opacity(0.5), lineWidth: 2)
                                .frame(width: 24, height: 24)

                            if hasAcceptedTerms {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Constants.Colors.gold)
                            }
                        }

                        Text("I accept the Privacy Policy and Terms of Service")
                            .font(.system(size: 13))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.top, 8)
            }
            .padding(.horizontal, 30)

            // Accept button
            Button {
                withAnimation {
                    showTutorial = true
                }
            } label: {
                Text("Accept & Continue")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(hasAcceptedTerms ? Constants.Colors.deepBlue : .gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(hasAcceptedTerms ? Constants.Colors.gold : Color.gray.opacity(0.3))
                    )
            }
            .disabled(!hasAcceptedTerms)
            .padding(.horizontal, 40)
            .padding(.top, 20)
            .padding(.bottom, 50)
        }
    }

    // MARK: - How to Play Page

    private var howToPlayPage: some View {
        VStack(spacing: 25) {
            Spacer()

            Text("How to Play")
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(Constants.Colors.gold)

            VStack(alignment: .leading, spacing: 20) {
                tutorialStep(
                    icon: "photo",
                    title: "Look at the Picture",
                    description: "Each puzzle shows a visual clue representing a word or phrase"
                )

                tutorialStep(
                    icon: "character.cursor.ibeam",
                    title: "Spell the Answer",
                    description: "Use the letter wheel to spell out what you see"
                )

                tutorialStep(
                    icon: "star.fill",
                    title: "Complete Constellations",
                    description: "Solve puzzles to light up stars and unlock new realms"
                )

                tutorialStep(
                    icon: "sparkles",
                    title: "Collect Spirits",
                    description: "Complete a constellation to earn a magical spirit companion"
                )
            }
            .padding(.horizontal, 30)

            Spacer()

            // Get Started button
            Button {
                onComplete()
            } label: {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(Constants.Colors.deepBlue)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(Constants.Colors.gold)
                    )
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }

    private func tutorialStep(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Constants.Colors.deepBlue)
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(Constants.Colors.gold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
