//
//  SplashScreenView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/29/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            // Pure white background
            Color.white
                .ignoresSafeArea()

            // NDMLABS text with elegant styling
            Text("NDMLABS")
                .font(.custom("Didot", size: 42))
                .fontWeight(.medium)
                .tracking(8) // Letter spacing for elegance
                .foregroundColor(.black)
                .opacity(opacity)
        }
        .onAppear {
            // Fade in the text
            withAnimation(.easeIn(duration: 0.8)) {
                opacity = 1
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
