//
//  PrivacyPolicyView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/30/25.
//

import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("PRIVACY POLICY")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Last updated: November 30, 2025")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Introduction
                    Text("This Privacy Notice for NDM Labs (\"we,\" \"us,\" or \"our\"), describes how and why we might access, collect, store, use, and/or share (\"process\") your personal information when you use our services (\"Services\"), including when you:")
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Download and use our mobile application (Puzzlore), or any other application of ours that links to this Privacy Notice")
                        bulletPoint("Engage with us in other related ways, including any sales, marketing, or events")
                    }

                    sectionHeader("SUMMARY OF KEY POINTS")

                    Text("This summary provides key points from our Privacy Notice, but you can find out more details about any of these topics by reading the full sections below.")
                        .font(.system(size: 14))
                        .italic()

                    keyPoint(
                        title: "What personal information do we process?",
                        content: "When you visit, use, or navigate our Services, we may process personal information depending on how you interact with us and the Services, the choices you make, and the products and features you use."
                    )

                    keyPoint(
                        title: "Do we process any sensitive personal information?",
                        content: "We do not process sensitive personal information."
                    )

                    keyPoint(
                        title: "Do we collect any information from third parties?",
                        content: "We do not collect any information from third parties."
                    )

                    keyPoint(
                        title: "How do we process your information?",
                        content: "We process your information to provide, improve, and administer our Services, communicate with you, for security and fraud prevention, and to comply with law."
                    )

                    keyPoint(
                        title: "How do we keep your information safe?",
                        content: "We have adequate organizational and technical processes and procedures in place to protect your personal information. However, no electronic transmission over the internet or information storage technology can be guaranteed to be 100% secure."
                    )

                    keyPoint(
                        title: "What are your rights?",
                        content: "Depending on where you are located geographically, the applicable privacy law may mean you have certain rights regarding your personal information."
                    )

                    sectionHeader("INFORMATION WE COLLECT")

                    Text("We collect personal information that you voluntarily provide to us when you express an interest in obtaining information about us or our products and Services, when you participate in activities on the Services, or otherwise when you contact us.")
                        .font(.system(size: 14))

                    Text("The personal information we collect may include:")
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Game progress and achievement data")
                        bulletPoint("Device information for app functionality")
                        bulletPoint("Usage data to improve the game experience")
                    }

                    sectionHeader("HOW WE USE YOUR INFORMATION")

                    Text("We use personal information collected via our Services for a variety of business purposes described below:")
                        .font(.system(size: 14))

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("To deliver and facilitate delivery of services to the user")
                        bulletPoint("To respond to user inquiries and offer support")
                        bulletPoint("To send administrative information")
                        bulletPoint("To protect our Services")
                        bulletPoint("To respond to legal requests and prevent harm")
                    }

                    sectionHeader("DATA RETENTION")

                    Text("We will only keep your personal information for as long as it is necessary for the purposes set out in this Privacy Notice, unless a longer retention period is required or permitted by law.")
                        .font(.system(size: 14))

                    sectionHeader("CONTACT US")

                    Text("If you have questions or comments about this notice, you may contact us at:")
                        .font(.system(size: 14))

                    Text("support@ndmlabs.com")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)

                    Spacer(minLength: 40)
                }
                .padding()
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(.primary)
            .padding(.top, 10)
    }

    private func keyPoint(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)

            Text(content)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 14))
            Text(text)
                .font(.system(size: 14))
        }
    }
}

#Preview {
    PrivacyPolicyView()
}
