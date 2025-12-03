
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

    // MARK: - State
    @StateObject private var progressManager = ProgressManager.shared
    @State private var currentInput = ""
    @State private var revealedIndices: Set<Int> = []
    @State private var shuffledLetters: [String] = []
    @State private var showingExplanation = false
    @State private var isCorrect = false
    @State private var wrongAnswerShake = false
    @State private var hintRevealed = false
    @State private var shufflesRemaining = 2
    @State private var rocketBoostUsed = false
    @State private var boostRevealedIndex: Int? = nil  // Shows first letter in slot as hint (user still inputs it)
    @State private var showingInsufficientFunds = false  // Popup when user can't afford hint/boost

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            // Get safe area from key window since GeometryReader with ignoresSafeArea reports 0
            let window = UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
            let topInset = window?.safeAreaInsets.top ?? 59
            let bottomInset = window?.safeAreaInsets.bottom ?? 34

            ZStack {
                backgroundLayer(geo: geo)

                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal)
                        .padding(.top, topInset + 8)

                    PuzzleImageView(imageName: puzzle.puzzleImage)
                        .padding(.top, 12)
                        .padding(.bottom, 24)

                    answerSlots

                    Spacer().frame(maxHeight: 16)

                    actionButtons

                    letterWheelSection
                        .padding(.horizontal)

                    Spacer(minLength: bottomInset)
                }

                if showingExplanation {
                    explanationOverlay
                }

                if showingInsufficientFunds {
                    insufficientFundsOverlay
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            shuffledLetters = puzzle.wheelLetters.shuffled()
        }
    }
}

// MARK: - Background
private extension PuzzleView {
    /// Gets the effective background for this puzzle (puzzle override or constellation default)
    var effectiveBackground: String {
        if let puzzleBackground = puzzle.background {
            return puzzleBackground
        }
        // Get constellation background as fallback
        if let constellation = PuzzleLoader.shared.constellation(containingPuzzle: puzzle.puzzleId) {
            return constellation.background
        }
        return ""
    }

    @ViewBuilder
    func backgroundLayer(geo: GeometryProxy) -> some View {
        let bgName = effectiveBackground
        let totalWidth = geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing
        let totalHeight = geo.size.height + geo.safeAreaInsets.top + geo.safeAreaInsets.bottom

        // Static image background for puzzle view
        if UIImage(named: bgName) != nil {
            Image(bgName)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: totalWidth, height: totalHeight)
                .position(x: totalWidth / 2, y: totalHeight / 2)
                .clipped()
        } else {
            Constants.Colors.backgroundGradient
        }
    }
}

// MARK: - Top Bar
private extension PuzzleView {
    var topBar: some View {
        HStack {
            // Back button
            Button(action: onExit) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 54, height: 54)
                    .background(
                        Circle()
                            .fill(Constants.Colors.deepBlue.opacity(0.8))
                    )
            }

            Spacer()

            // Context tag (hint) - shown when revealed
            if hintRevealed {
                Text(puzzle.contextTag)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Constants.Colors.purple.opacity(0.6))
                            .overlay(
                                Capsule()
                                    .stroke(Constants.Colors.gold.opacity(0.4), lineWidth: 1)
                            )
                    )
                    .transition(.opacity.combined(with: .scale))
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
}

// MARK: - Context Tag
private extension PuzzleView {
    var contextTag: some View {
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
}

// MARK: - Answer Slots
private extension PuzzleView {
    var answerSlots: some View {
        AnswerSlotsView(
            answerLength: puzzle.answer.count,
            currentInput: currentInput,
            anchorLetters: anchorLettersDict,
            revealedIndices: revealedIndices,
            correctAnswer: puzzle.answer,
            isCorrect: isCorrect,
            boostHintIndex: boostRevealedIndex
        )
        .offset(x: wrongAnswerShake ? 10 : 0)
    }
}

// MARK: - Action Buttons
private extension PuzzleView {
    var actionButtons: some View {
        HStack {
            // Shuffle button
            Button {
                if shufflesRemaining > 0 {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        shuffledLetters = shuffledLetters.shuffledDifferently()
                        shufflesRemaining -= 1
                    }
                }
            } label: {
                actionButton(
                    icon: "shuffle",
                    label: "Shuffle",
                    color: shufflesRemaining > 0 ? .white.opacity(0.8) : .gray
                )
            }
            .disabled(shufflesRemaining <= 0)

            Spacer()

            // Hint button
            Button(action: useHint) {
                actionButton(
                    icon: hintRevealed ? "lightbulb.fill" : "lightbulb",
                    label: "Hint",
                    color: hintRevealed ? .gray : Constants.Colors.gold
                )
            }
            .disabled(hintRevealed)
        }
        .padding(.horizontal, 30)
    }

    func actionButton(icon: String, label: String, color: Color = .white.opacity(0.8)) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 20))

            Text(label)
                .font(.system(size: 10))
        }
        .foregroundColor(color)
        .frame(width: 60, height: 60)
        .background(
            Circle()
                .fill(Constants.Colors.deepBlue.opacity(0.8))
        )
    }
}

// MARK: - Letter Wheel + Rocket Boost Button
private extension PuzzleView {
    var letterWheelSection: some View {
        ZStack(alignment: .bottomLeading) {
            LetterWheelView(
                letters: shuffledLetters,
                onWordSubmit: handleWordSubmit,
                onWordChange: { word in
                    if !isCorrect { currentInput = word }
                }
            )

            Button(action: useRocketBoost) {
                VStack(spacing: 2) {
                    Image(systemName: rocketBoostUsed ? "bolt.fill" : "bolt")
                        .font(.system(size: 18))
                    Text("Boost")
                        .font(.system(size: 9))
                }
                .foregroundColor(rocketBoostUsed ? .gray : Constants.Colors.starCyan)
                .frame(width: 54, height: 54)
                .background(
                    Circle().fill(Constants.Colors.deepBlue.opacity(0.8))
                )
            }
            .disabled(rocketBoostUsed)
            .offset(x: 16, y: -16)
        }
    }
}

// MARK: - Explanation Overlay
private extension PuzzleView {
    var explanationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    showingExplanation = false
                    onComplete()
                }

            VStack(spacing: 24) {
                Image(systemName: "star.fill")
                    .font(.system(size: 60))
                    .foregroundColor(Constants.Colors.starGold)
                    .glow(color: Constants.Colors.starGold, radius: 20)

                Text(puzzle.answer)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(puzzle.explanation.breakdown)
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)

                rewardView

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

    var rewardView: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .foregroundColor(Constants.Colors.starGold)

            Text("+\(puzzle.moonstoneReward)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Constants.Colors.starGold)
        }
        .padding(.top, 10)
    }
}

// MARK: - Insufficient Funds Toast
private extension PuzzleView {
    var insufficientFundsOverlay: some View {
        VStack {
            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Constants.Colors.starGold.opacity(0.7))

                Text("Not enough")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Constants.Colors.deepBlue.opacity(0.95))
                    .overlay(
                        Capsule()
                            .stroke(Constants.Colors.gold.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
            .padding(.bottom, 200)
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    showingInsufficientFunds = false
                }
            }
        }
    }
}

// MARK: - Logic
private extension PuzzleView {
    var anchorLettersDict: [Int: String] {
        var dict: [Int: String] = [:]
        let answerArray = Array(puzzle.answer)

        for index in puzzle.anchorLetters where index < answerArray.count {
            dict[index] = String(answerArray[index])
        }
        return dict
    }

    func handleWordSubmit(_ word: String) {
        currentInput = word

        let fullAnswer = buildFullAnswer(from: word)

        if fullAnswer.uppercased() == puzzle.answer.uppercased() {
            correctAnswerSequence()
        } else if fullAnswer.count == puzzle.answer.count {
            wrongAnswerSequence()
        }
    }

    func correctAnswerSequence() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isCorrect = true
        }

        progressManager.completePuzzle(puzzle)

        UINotificationFeedbackGenerator().notificationOccurred(.success)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation(.spring()) {
                showingExplanation = true
            }
        }
    }

    func wrongAnswerSequence() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)

        withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
            wrongAnswerShake = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.1, dampingFraction: 0.3)) {
                wrongAnswerShake = false
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            currentInput = ""
        }
    }

    func buildFullAnswer(from input: String) -> String {
        var result = Array(repeating: "", count: puzzle.answer.count)
        let answerArray = Array(puzzle.answer)
        let inputArray = Array(input)

        // Fill anchors + revealed
        for (i, letter) in anchorLettersDict { result[i] = letter }
        for i in revealedIndices where i < answerArray.count { result[i] = String(answerArray[i]) }

        // Fill remaining with input letters (in order)
        var inputIndex = 0
        for i in 0..<result.count where result[i].isEmpty {
            if inputIndex < inputArray.count {
                result[i] = String(inputArray[inputIndex])
                inputIndex += 1
            }
        }

        return result.joined()
    }

    func useHint() {
        // If hint not yet revealed, reveal the context tag
        guard !hintRevealed else { return }

        guard progressManager.progress.canAfford(Constants.Economy.revealLetterCost) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.spring()) {
                showingInsufficientFunds = true
            }
            return
        }

        if progressManager.spend(Constants.Economy.revealLetterCost) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            progressManager.useHint()
            withAnimation(.spring()) {
                hintRevealed = true
            }
        }
    }

    func useRocketBoost() {
        // Can only use once per puzzle
        guard !rocketBoostUsed else { return }

        guard progressManager.progress.canAfford(Constants.Economy.rocketBoostCost) else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.spring()) {
                showingInsufficientFunds = true
            }
            return
        }

        // Get the first letter index of the answer (skipping any anchor letters)
        let answerArray = Array(puzzle.answer)
        var firstLetterIndex: Int?

        for i in 0..<answerArray.count {
            if anchorLettersDict[i] == nil {
                firstLetterIndex = i
                break
            }
        }

        guard let index = firstLetterIndex else { return }

        if progressManager.spend(Constants.Economy.rocketBoostCost) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()

            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                // Show the first letter in the slot as a hint - user still needs to input it
                boostRevealedIndex = index
                rocketBoostUsed = true
            }
        }
    }
}
