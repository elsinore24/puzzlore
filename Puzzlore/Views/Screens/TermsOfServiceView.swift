//
//  TermsOfServiceView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/30/25.
//

import SwiftUI

struct TermsOfServiceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("TERMS OF SERVICE")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.primary)

                        Text("Last updated: November 30, 2025")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // Introduction
                    Text("These Terms of Service (\"Terms\") govern your use of Puzzlore (the \"App\") provided by NDM Labs (\"we,\" \"us,\" or \"our\"). By downloading, installing, or using the App, you agree to be bound by these Terms.")
                        .font(.system(size: 14))

                    sectionHeader("1. ACCEPTANCE OF TERMS")

                    Text("By accessing or using the App, you confirm that you have read, understood, and agree to be bound by these Terms. If you do not agree to these Terms, you may not use the App.")
                        .font(.system(size: 14))

                    sectionHeader("2. ELIGIBILITY")

                    Text("You must be at least 13 years old to use this App. By using the App, you represent and warrant that you meet this age requirement. If you are under 18, you should review these Terms with a parent or guardian.")
                        .font(.system(size: 14))

                    sectionHeader("3. LICENSE TO USE")

                    Text("We grant you a limited, non-exclusive, non-transferable, revocable license to use the App for your personal, non-commercial use, subject to these Terms.")
                        .font(.system(size: 14))

                    Text("You may not:")
                        .font(.system(size: 14))
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Copy, modify, or distribute the App")
                        bulletPoint("Reverse engineer or attempt to extract the source code")
                        bulletPoint("Use the App for any unlawful purpose")
                        bulletPoint("Transfer your license to anyone else")
                        bulletPoint("Use automated systems to access the App")
                    }

                    sectionHeader("4. USER CONTENT")

                    Text("The App may allow you to save game progress and achievements. You retain ownership of any personal data you provide, but you grant us permission to use this data to provide and improve the Services.")
                        .font(.system(size: 14))

                    sectionHeader("5. INTELLECTUAL PROPERTY")

                    Text("All content in the App, including but not limited to text, graphics, logos, images, audio, and software, is the property of NDM Labs or its licensors and is protected by intellectual property laws.")
                        .font(.system(size: 14))

                    sectionHeader("6. IN-APP PURCHASES")

                    Text("The App may offer in-app purchases. All purchases are final and non-refundable, except as required by applicable law. You are responsible for all charges incurred through your account.")
                        .font(.system(size: 14))

                    sectionHeader("7. DISCLAIMER OF WARRANTIES")

                    Text("THE APP IS PROVIDED \"AS IS\" AND \"AS AVAILABLE\" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR FREE OF HARMFUL COMPONENTS.")
                        .font(.system(size: 14))

                    sectionHeader("8. LIMITATION OF LIABILITY")

                    Text("TO THE MAXIMUM EXTENT PERMITTED BY LAW, NDM LABS SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF YOUR USE OF THE APP.")
                        .font(.system(size: 14))

                    sectionHeader("9. TERMINATION")

                    Text("We may terminate or suspend your access to the App at any time, without prior notice or liability, for any reason, including if you breach these Terms.")
                        .font(.system(size: 14))

                    sectionHeader("10. CHANGES TO TERMS")

                    Text("We reserve the right to modify these Terms at any time. We will notify you of any changes by posting the new Terms in the App. Your continued use of the App after such changes constitutes your acceptance of the new Terms.")
                        .font(.system(size: 14))

                    sectionHeader("11. GOVERNING LAW")

                    Text("These Terms shall be governed by and construed in accordance with the laws of the United States, without regard to its conflict of law provisions.")
                        .font(.system(size: 14))

                    sectionHeader("12. CONTACT US")

                    Text("If you have any questions about these Terms, please contact us at:")
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
    TermsOfServiceView()
}
