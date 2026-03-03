import SwiftUI
import AppKit

// Behaviors / states
enum PetState {
    case running
    case idleStanding      // static frontstanding
    case idleAnimating     // 2-frame idle animation
}

struct PetView: View {
    @EnvironmentObject var model: PetWindowModel

    // Position in window coordinates (NOT screen coords)
    @State private var pos: CGPoint = .zero

    // Keep your current speed
    @State private var velocity: CGFloat = 2.0
    @State private var goingRight: Bool = true

    @State private var isTalking: Bool = false
    @State private var speechText: String = "hi!"

    // State machine
    @State private var state: PetState = .running

    // Running animation frames
    @State private var runFrame: Int = 0

    // Idle animation frames (2 pngs)
    @State private var idleFrame: Int = 0

    @State private var frameTick: Int = 0

    // Long-run targeting (prevents short back-and-forth)
    @State private var runTarget: CGPoint? = nil

    // Axis movement flag (no diagonals)
    @State private var movingHorizontally: Bool = true

    // Visual sizes
    private let spriteSize: CGFloat = 40
    private let bubbleOffset = CGSize(width: 36, height: 36)

    // Window/canvas size (matches your Rectangle frame)
    private let canvasSize = CGSize(width: 1475, height: 925)

    // MARK: - ASSET NAMES (NO .png)
    private let runA = "rightwalking1"
    private let runB = "rightwalking2"

    // 2) standing still
    private let standFront = "frontstanding"

    // 3) idle 2-frame animation (CHANGE THESE TWO)
    private let idleA = "idle1"   // <-- replace with your asset name
    private let idleB = "idle2"   // <-- replace with your asset name

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Transparent "canvas" for the window content
            Rectangle()
                .fill(Color.white.opacity(0.0001))
                .frame(width: canvasSize.width, height: canvasSize.height)
                // Debug border (optional): uncomment to see bounds
                // .overlay(Rectangle().stroke(Color.red.opacity(0.4), lineWidth: 1))

            petSprite
                .position(x: pos.x, y: pos.y)

            if isTalking {
                let bp = bubblePosition()
                speechBubble(text: speechText)
                    .position(x: bp.x, y: bp.y)
                    .transition(.opacity)
            }
        }
        .onAppear {
            // Start centered so you can SEE it roam
            pos = CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2)
            clampPosIntoBounds()
            startLoop()
            startRunAroundScreenBehavior()
        }
    }

    // MARK: - Sprite

    private var petSprite: some View {
        let assetName: String

        switch state {
        case .running:
            assetName = (runFrame == 0) ? runA : runB
        case .idleStanding:
            assetName = standFront
        case .idleAnimating:
            assetName = (idleFrame == 0) ? idleA : idleB
        }

        return Image(assetName)
            .interpolation(.none)
            .resizable()
            .frame(width: spriteSize, height: spriteSize)
            .scaleEffect(x: goingRight ? 1 : -1, y: 1)
    }

    // MARK: - Speech bubble

    private func speechBubble(text: String) -> some View {
        Text(text)
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundColor(.black)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.95))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
            .fixedSize()
    }

    @MainActor
    private func bubblePosition() -> CGPoint {
        // desired bubble spot
        let desiredX = pos.x + bubbleOffset.width
        let desiredY = pos.y + bubbleOffset.height

        // keep bubble roughly in bounds
        let half = spriteSize / 2
        let minX = half
        let maxX = canvasSize.width - half
        let minY = half
        let maxY = canvasSize.height - half

        return CGPoint(
            x: min(max(desiredX, minX), maxX),
            y: min(max(desiredY, minY), maxY)
        )
    }

    // MARK: - Main Loop

    private func startLoop() {
        Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            Task { @MainActor in
                frameTick += 1

                // Running walk cycle (~6fps)
                if state == .running, frameTick % 10 == 0 {
                    runFrame = 1 - runFrame
                }

                // Idle anim cycle (~3fps)
                if state == .idleAnimating, frameTick % 20 == 0 {
                    idleFrame = 1 - idleFrame
                }

                // Only move in running mode
                guard state == .running else { return }

                updateRunMovement()
            }
        }
    }

    // =========================================================
    // 1) BEHAVIOR: run around screen (NO diagonals)
    // =========================================================

    @MainActor
    private func startRunAroundScreenBehavior() {
        state = .running
        pickFarRunTarget()
    }

    @MainActor
    private func updateRunMovement() {
        guard let target = runTarget else {
            pickFarRunTarget()
            return
        }

        if movingHorizontally {
            let dx = target.x - pos.x
            goingRight = dx >= 0
            let step = (dx >= 0) ? velocity : -velocity

            // If we'd pass target, snap to it
            if abs(dx) <= abs(step) {
                pos.x = target.x
                pickFarRunTarget()
            } else {
                pos.x += step
            }
        } else {
            let dy = target.y - pos.y
            let step = (dy >= 0) ? velocity : -velocity

            if abs(dy) <= abs(step) {
                pos.y = target.y
                pickFarRunTarget()
            } else {
                pos.y += step
            }
        }

        clampPosIntoBounds()

        // Occasionally switch behavior
        if Int.random(in: 0...1200) == 0 {
            if Bool.random() {
                standStillFrontBehavior()
            } else {
                idleTwoFrameBehavior()
            }
        }
    }

    @MainActor
    private func pickFarRunTarget() {
        let half = spriteSize / 2
        let minX = half
        let maxX = canvasSize.width - half
        let minY = half
        let maxY = canvasSize.height - half

        // Choose axis
        movingHorizontally = Bool.random()

        if movingHorizontally {
            // Force a full cross-window move left/right (prevents tiny bounces)
            let x: CGFloat = (pos.x < canvasSize.width / 2) ? maxX : minX
            runTarget = CGPoint(x: x, y: pos.y)
        } else {
            // Force a full cross-window move up/down
            let y: CGFloat = (pos.y < canvasSize.height / 2) ? maxY : minY
            runTarget = CGPoint(x: pos.x, y: y)
        }
    }

    // =========================================================
    // 2) BEHAVIOR: static stand (frontstanding) 30–60s
    // =========================================================

    @MainActor
    private func standStillFrontBehavior() {
        state = .idleStanding
        saySomethingQuick()

        let seconds = Double.random(in: 30.0...60.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            Task { @MainActor in
                startRunAroundScreenBehavior()
            }
        }
    }

    // =========================================================
    // 3) BEHAVIOR: idle 2-frame anim (no movement) 30–60s
    // =========================================================

    @MainActor
    private func idleTwoFrameBehavior() {
        state = .idleAnimating
        idleFrame = 0
        saySomethingQuick()

        let seconds = Double.random(in: 30.0...60.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
            Task { @MainActor in
                startRunAroundScreenBehavior()
            }
        }
    }

    // MARK: - Talk helper

    @MainActor
    private func saySomethingQuick() {
        isTalking = true
        speechText = ["hello", "brb", "nyc vibes", "genki grind", "😄"].randomElement()!

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.15)) {
                    isTalking = false
                }
            }
        }
    }

    // MARK: - Bounds

    @MainActor
    private func clampPosIntoBounds() {
        let half = spriteSize / 2
        pos.x = min(max(pos.x, half), canvasSize.width - half)
        pos.y = min(max(pos.y, half), canvasSize.height - half)
    }
}
