//
//  AnswerSlotsView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import SwiftUI

struct AnswerSlotsView: View {
    let answerLength: Int
    let currentInput: String
    let anchorLetters: [Int: String] // Index -> Letter for pre-filled hints
    let revealedIndices: Set<Int> // Indices revealed via hints
    let correctAnswer: String
    var isCorrect: Bool = false  // When true, show green success state

    @State private var shakeOffset: CGFloat = 0
    @State private var showingCorrect: Bool = false

    private let slotSize: CGFloat = 36
    private let spacing: CGFloat = 6

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(0..<answerLength, id: \.self) { index in
                slotView(for: index)
            }
        }
        .offset(x: shakeOffset)
    }

    @ViewBuilder
    private func slotView(for index: Int) -> some View {
        let letter = letterFor(index: index)
        let isAnchor = anchorLetters[index] != nil
        let isRevealed = revealedIndices.contains(index)
        let isFilled = letter != nil

        ZStack {
            // Slot background - frosted glass for empty slots
            if !isFilled && !isAnchor && !isRevealed && !isCorrect {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.thinMaterial.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(slotBackgroundColor(isAnchor: isAnchor, isRevealed: isRevealed, isFilled: isFilled))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(slotBorderColor(isAnchor: isAnchor, isRevealed: isRevealed, isFilled: isFilled), lineWidth: 2)
                    )
            }

            // Letter
            if let letter = letter {
                Text(letter)
                    .font(.system(size: slotSize * 0.6, weight: .bold, design: .rounded))
                    .foregroundColor(letterColor(isAnchor: isAnchor, isRevealed: isRevealed))
            }
        }
        .frame(width: slotSize, height: slotSize * 1.2)
    }

    private func letterFor(index: Int) -> String? {
        // Priority: anchor letters > revealed letters > current input
        if let anchor = anchorLetters[index] {
            return anchor
        }

        if revealedIndices.contains(index) {
            let answerArray = Array(correctAnswer)
            if index < answerArray.count {
                return String(answerArray[index])
            }
        }

        // Current input fills remaining slots left-to-right, skipping anchors/revealed
        var inputIndex = 0
        for i in 0..<answerLength {
            if anchorLetters[i] == nil && !revealedIndices.contains(i) {
                if i == index {
                    let inputArray = Array(currentInput)
                    if inputIndex < inputArray.count {
                        return String(inputArray[inputIndex])
                    }
                    return nil
                }
                inputIndex += 1
            }
        }

        return nil
    }

    // MARK: - Colors

    private func slotBackgroundColor(isAnchor: Bool, isRevealed: Bool, isFilled: Bool) -> Color {
        if isCorrect {
            return Color.green.opacity(0.5)
        }
        if isAnchor || isRevealed {
            return Constants.Colors.gold.opacity(0.2)
        }
        if isFilled {
            return Constants.Colors.starCyan.opacity(0.2)
        }
        return .clear // Use clear for frosted glass effect
    }

    private func slotBorderColor(isAnchor: Bool, isRevealed: Bool, isFilled: Bool) -> Color {
        if isCorrect {
            return Color.green
        }
        if isAnchor || isRevealed {
            return Constants.Colors.gold.opacity(0.8)
        }
        if isFilled {
            return Constants.Colors.starCyan.opacity(0.8)
        }
        return Constants.Colors.gold.opacity(0.3)
    }

    private func letterColor(isAnchor: Bool, isRevealed: Bool) -> Color {
        if isCorrect {
            return .white
        }
        if isAnchor || isRevealed {
            return Constants.Colors.gold
        }
        return .white
    }

    // MARK: - Animations

    func shakeWrong() {
        withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
            shakeOffset = 10
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                shakeOffset = -10
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                shakeOffset = 0
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Constants.Colors.backgroundGradient
            .ignoresSafeArea()

        VStack(spacing: 40) {
            // Empty slots
            AnswerSlotsView(
                answerLength: 9,
                currentInput: "",
                anchorLetters: [:],
                revealedIndices: [],
                correctAnswer: "MOONLIGHT"
            )

            // Partial input
            AnswerSlotsView(
                answerLength: 9,
                currentInput: "MOON",
                anchorLetters: [:],
                revealedIndices: [],
                correctAnswer: "MOONLIGHT"
            )

            // With anchor and revealed
            AnswerSlotsView(
                answerLength: 9,
                currentInput: "MO",
                anchorLetters: [4: "L"],
                revealedIndices: [8],
                correctAnswer: "MOONLIGHT"
            )
        }
    }
}
