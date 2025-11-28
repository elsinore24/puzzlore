//
//  LetterWheelView.swift
//  Puzzlore
//
//  Created by Daniel Merryman on 11/27/25.
//

import SwiftUI

struct LetterWheelView: View {
    let letters: [String]
    let onWordSubmit: (String) -> Void
    var onWordChange: ((String) -> Void)? = nil  // Real-time callback as user swipes

    @State private var selectedIndices: [Int] = []
    @State private var letterPositions: [Int: CGPoint] = [:]
    @State private var currentDragLocation: CGPoint? = nil
    @State private var wheelRotation: Double = 0

    private let letterSize: CGFloat = 52
    private let wheelRadius: CGFloat = 110

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)

            ZStack {
                // Wheel background - frosted glass with glow
                Circle()
                    .fill(.thinMaterial.opacity(0.7))
                    .frame(width: wheelRadius * 2 + letterSize, height: wheelRadius * 2 + letterSize)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.35), lineWidth: 1)
                    )
                    .shadow(color: Color.white.opacity(0.4), radius: 15, x: 0, y: 0)
                    .shadow(color: Color.white.opacity(0.3), radius: 30, x: 0, y: 0)
                    .shadow(color: Constants.Colors.starCyan.opacity(0.25), radius: 50, x: 0, y: 0)
                    .shadow(color: Constants.Colors.starCyan.opacity(0.15), radius: 80, x: 0, y: 0)
                    .position(center)

                // Connection lines between selected letters
                if selectedIndices.count > 0 {
                    Path { path in
                        for (index, letterIndex) in selectedIndices.enumerated() {
                            if let pos = letterPositions[letterIndex] {
                                if index == 0 {
                                    path.move(to: pos)
                                } else {
                                    path.addLine(to: pos)
                                }
                            }
                        }
                        // Line to current drag position
                        if let dragLoc = currentDragLocation, !selectedIndices.isEmpty {
                            path.addLine(to: dragLoc)
                        }
                    }
                    .stroke(
                        Constants.Colors.starCyan,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                    )
                    .glow(color: Constants.Colors.starCyan, radius: 8)
                }

                // Letters arranged in circle
                ForEach(Array(letters.enumerated()), id: \.offset) { index, letter in
                    let angle = angleForIndex(index, total: letters.count)
                    let position = positionForAngle(angle, center: center, radius: wheelRadius)

                    LetterNode(
                        letter: letter,
                        isSelected: selectedIndices.contains(index),
                        size: letterSize
                    )
                    .position(position)
                    .onAppear {
                        letterPositions[index] = position
                    }
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(at: value.location, center: center)
                    }
                    .onEnded { _ in
                        submitWord()
                    }
            )
        }
        .frame(height: wheelRadius * 2 + letterSize + 20)
    }

    // MARK: - Geometry Helpers

    private func angleForIndex(_ index: Int, total: Int) -> Double {
        let baseAngle = -(Double.pi / 2) // Start at top
        let angleStep = (2 * Double.pi) / Double(total)
        return baseAngle + (Double(index) * angleStep) + wheelRotation
    }

    private func positionForAngle(_ angle: Double, center: CGPoint, radius: CGFloat) -> CGPoint {
        CGPoint(
            x: center.x + radius * Darwin.cos(angle),
            y: center.y + radius * Darwin.sin(angle)
        )
    }

    // MARK: - Drag Handling

    private func handleDrag(at location: CGPoint, center: CGPoint) {
        currentDragLocation = location

        // Find the closest letter to the drag location
        var closestIndex: Int? = nil
        var closestDistance: CGFloat = .infinity

        for (index, position) in letterPositions {
            let distance = hypot(location.x - position.x, location.y - position.y)
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }

        // Only select if finger is actually over the letter (tighter radius)
        guard let index = closestIndex, closestDistance < letterSize / 2 else {
            return
        }

        // If this letter is already the last selected, do nothing
        if selectedIndices.last == index {
            return
        }

        // If this letter was previously selected (backtracking), remove subsequent selections
        if let existingIndex = selectedIndices.firstIndex(of: index) {
            selectedIndices = Array(selectedIndices.prefix(existingIndex + 1))
            notifyWordChange()
            return
        }

        // Add new letter to selection
        selectedIndices.append(index)

        // Notify real-time change
        notifyWordChange()

        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func notifyWordChange() {
        let word = selectedIndices.map { letters[$0] }.joined()
        onWordChange?(word)
    }

    private func submitWord() {
        let word = selectedIndices.map { letters[$0] }.joined()

        if !word.isEmpty {
            onWordSubmit(word)
        }

        // Clear preview
        onWordChange?("")

        // Reset selection
        withAnimation(.easeOut(duration: 0.2)) {
            selectedIndices = []
            currentDragLocation = nil
        }
    }

    // MARK: - Shuffle

    func shuffle() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            wheelRotation += Double.pi / Double(letters.count)
        }
    }
}

// MARK: - Letter Node

struct LetterNode: View {
    let letter: String
    let isSelected: Bool
    let size: CGFloat

    var body: some View {
        Text(letter)
            .font(.system(size: size * 0.6, weight: .semibold, design: .serif))
            .foregroundColor(isSelected ? Constants.Colors.starCyan : .white.opacity(0.9))
            .shadow(color: .white.opacity(0.3), radius: 4, x: 0, y: 0)
            .shadow(color: isSelected ? Constants.Colors.starCyan.opacity(0.9) : .white.opacity(0.15), radius: 8, x: 0, y: 0)
            .shadow(color: isSelected ? Constants.Colors.starCyan.opacity(0.6) : .clear, radius: 15, x: 0, y: 0)
            .frame(width: size, height: size)
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Constants.Colors.backgroundGradient
            .ignoresSafeArea()

        VStack {
            Spacer()

            LetterWheelView(
                letters: ["M", "O", "O", "N", "L", "I", "G", "H", "T", "S", "E", "A"],
                onWordSubmit: { word in
                    print("Submitted: \(word)")
                }
            )
            .padding()
        }
    }
}
