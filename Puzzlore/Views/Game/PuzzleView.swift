//
//  PuzzleView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import SwiftUI

struct PuzzleView: View {
    let puzzle: Puzzle
    let onComplete: () -> Void
    let onExit: () -> Void

    @StateObject private var progressManager = ProgressManager.shared

    @State private var currentInput: String = ""
    @State private var revealedIndices: Set<Int> = []
    @State private var shuffledLetters: [String] = []
    @State private var showingExplanation: Bool = false
    @State private var isCorrect: Bool = false
    @State private var wrongAnswerShake: Bool = false

    var body: some View {
        ZStack {
            // Background image or fallback gradient
            backgroundView
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar
                topBar
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Context tag (hint category)
                contextTag
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                // Puzzle image in frosted glass container
                PuzzleImageView(imageName: puzzle.puzzleImage)
                    .padding(.bottom, 24)

                // Answer slots
                AnswerSlotsView(
                    answerLength: puzzle.answer.count,
                    currentInput: currentInput,
                    anchorLetters: anchorLettersDict,
                    revealedIndices: revealedIndices,
                    correctAnswer: puzzle.answer,
                    isCorrect: isCorrect
                )
                .offset(x: wrongAnswerShake ? 10 : 0)

                Spacer().frame(maxHeight: 16)

                // Action buttons (shuffle and hint on sides)
                actionButtons

                // Letter wheel with clear button overlay
                ZStack(alignment: .bottomLeading) {
                    LetterWheelView(
                        letters: shuffledLetters,
                        onWordSubmit: handleWordSubmit,
                        onWordChange: { word in
                            // Don't clear input if we already got it correct
                            if !isCorrect {
                                currentInput = word
                            }
                        }
                    )

                    // Clear button in lower left
                    Button {
                        currentInput = ""
                    } label: {
                        VStack(spacing: 2) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 18))
                            Text("Clear")
                                .font(.system(size: 9))
                        }
                        .foregroundColor(.white.opacity(0.8))
                        .frame(width: 54, height: 54)
                        .background(
                            Circle()
                                .fill(.thinMaterial.opacity(0.7))
                        )
                    }
                    .offset(x: 16, y: -16)
                }
                .padding(.horizontal)
            }

            // Success overlay
            if showingExplanation {
                explanationOverlay
            }
        }
        .onAppear {
            shuffledLetters = puzzle.wheelLetters.shuffled()
        }
    }

    // MARK: - Subviews

    @ViewBuilder
    private var backgroundView: some View {
        GeometryReader { geometry in
            if let _ = UIImage(named: puzzle.background) {
                Image(puzzle.background)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
            } else {
                Constants.Colors.backgroundGradient
            }
        }
        .ignoresSafeArea()
    }

    private var topBar: some View {
        HStack {
            // Back button
            Button {
                onExit()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
            }

            Spacer()

            // Currency display
            HStack(spacing: 4) {
                Image(systemName: "moon.stars.fill")
                    .foregroundColor(Constants.Colors.starGold)
                Text("\(progressManager.progress.currency)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Constants.Colors.deepBlue.opacity(0.8))
            )
        }
    }

    private var contextTag: some View {
        Text(puzzle.contextTag)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Constants.Colors.purple.opacity(0.6))
                    .overlay(
                        Capsule()
                            .stroke(Constants.Colors.gold.opacity(0.4), lineWidth: 1)
                    )
            )
    }

    private var actionButtons: some View {
        HStack {
            // Shuffle button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    shuffledLetters = shuffledLetters.shuffledDifferently()
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 20))
                    Text("Shuffle")
                        .font(.system(size: 10))
                }
                .foregroundColor(.white.opacity(0.8))
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(.thinMaterial.opacity(0.7))
                )
            }

            Spacer()

            // Hint button
            Button {
                useHint()
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 20))
                    Text("Hint")
                        .font(.system(size: 10))
                }
                .foregroundColor(Constants.Colors.gold)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(.thinMaterial.opacity(0.7))
                )
            }
        }
        .padding(.horizontal, 30)
    }

    private var explanationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    showingExplanation = false
                    onComplete()
                }

            VStack(spacing: 24) {
                // Success icon
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.starGold)
                    .glow(color: Constants.Colors.starGold, radius: 20)

                // Answer
                Text(puzzle.answer)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Explanation
                Text(puzzle.explanation.breakdown)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                // Reward
                HStack {
                    Image(systemName: "moon.stars.fill")
                        .foregroundColor(Constants.Colors.starGold)
                    Text("+\(puzzle.moonstoneReward)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(Constants.Colors.starGold)
                }
                .padding(.top, 10)

                // Continue button
                Button {
                    showingExplanation = false
                    onComplete()
                } label: {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Constants.Colors.deepBlue)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(Constants.Colors.gold)
                        )
                }
                .padding(.top, 10)
            }
            .padding(30)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Constants.Colors.deepBlue)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Constants.Colors.gold.opacity(0.5), lineWidth: 2)
                    )
            )
            .padding(40)
        }
    }

    // MARK: - Logic

    private var anchorLettersDict: [Int: String] {
        var dict: [Int: String] = [:]
        for index in puzzle.anchorLetters {
            let answerArray = Array(puzzle.answer)
            if index < answerArray.count {
                dict[index] = String(answerArray[index])
            }
        }
        return dict
    }

    private func handleWordSubmit(_ word: String) {
        currentInput = word

        // Build full answer including anchors and revealed letters
        let fullAnswer = buildFullAnswer(from: word)

        if fullAnswer.uppercased() == puzzle.answer.uppercased() {
            // Correct!
            withAnimation(.easeInOut(duration: 0.3)) {
                isCorrect = true
            }
            progressManager.completePuzzle(puzzle)

            // Haptic feedback
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)

            // Show explanation after 2 second delay to show green success state
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.spring()) {
                    showingExplanation = true
                }
            }
        } else if fullAnswer.count == puzzle.answer.count {
            // Wrong answer (but complete length)
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.error)

            // Shake animation
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                wrongAnswerShake = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                    wrongAnswerShake = false
                }
            }

            // Clear input after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                currentInput = ""
            }
        }
    }

    private func buildFullAnswer(from input: String) -> String {
        var result = Array(repeating: "", count: puzzle.answer.count)
        let answerArray = Array(puzzle.answer)

        // Fill anchors
        for (index, letter) in anchorLettersDict {
            result[index] = letter
        }

        // Fill revealed
        for index in revealedIndices {
            if index < answerArray.count {
                result[index] = String(answerArray[index])
            }
        }

        // Fill remaining with input
        var inputIndex = 0
        let inputArray = Array(input)
        for i in 0..<result.count {
            if result[i].isEmpty {
                if inputIndex < inputArray.count {
                    result[i] = String(inputArray[inputIndex])
                    inputIndex += 1
                }
            }
        }

        return result.joined()
    }

    private func useHint() {
        guard progressManager.progress.canAfford(Constants.Economy.revealLetterCost) else {
            // TODO: Show "not enough moonstones" message
            return
        }

        // Find an unrevealed, non-anchor index
        for i in 0..<puzzle.answer.count {
            if anchorLettersDict[i] == nil && !revealedIndices.contains(i) {
                if progressManager.spend(Constants.Economy.revealLetterCost) {
                    progressManager.useHint()
                    _ = withAnimation {
                        revealedIndices.insert(i)
                    }
                }
                break
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PuzzleView(
        puzzle: Puzzle(
            puzzleId: "preview_001",
            theme: "forest",
            galaxy: "nature",
            contextTag: "Something You See at Night",
            background: "enchanted_forest_01",
            puzzleImage: "nature_forest_001",
            answer: "MOONLIGHT",
            letters: ["M", "O", "O", "N", "L", "I", "G", "H", "T"],
            distractorLetters: ["S", "E", "A"],
            difficulty: 1,
            anchorLetters: [],
            explanation: PuzzleExplanation(
                breakdown: "Moon (crescent moon) + Light (lightbulb) = Moonlight",
                logicType: .compoundWord
            )
        ),
        onComplete: {},
        onExit: {}
    )
}
