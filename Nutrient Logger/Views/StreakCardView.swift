import SwiftUI

struct StreakCardView: View {
    let count: Int
    let unit: String
    let milestones: Set<Int>

    @State private var flameBouncing = false
    @State private var cardScale: CGFloat = 1.0
    @State private var particles: [StreakParticle] = []
    @State private var displayedProgress: Double = 0

    private var sortedMilestones: [Int] { milestones.sorted() }

    private var nextMilestone: Int? {
        sortedMilestones.first { $0 > count }
    }

    private var previousMilestone: Int {
        sortedMilestones.last { $0 <= count } ?? 0
    }

    private var progress: Double {
        guard let next = nextMilestone, next > previousMilestone else { return 1.0 }
        return Double(count - previousMilestone) / Double(next - previousMilestone)
    }

    var body: some View {
        if count > 0 {
            HStack(spacing: 8) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(.orange)
                    .symbolEffect(.bounce, value: flameBouncing)
                    .overlay {
                        ZStack {
                            ForEach(particles) { particle in
                                StreakParticleView(particle: particle)
                            }
                        }
                        .allowsHitTesting(false)
                    }
                Text("\(count)-\(unit) Streak")
                    .font(.subheadline.bold())
                    .foregroundStyle(.orange)
                    .contentTransition(.numericText())
                Spacer()
                if nextMilestone != nil {
                    HStack(spacing: 6) {
                        ProgressView(value: displayedProgress)
                            .tint(.orange)
                            .frame(width: 60)
                        Text("\(nextMilestone!)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .inCard(backgroundColor: .orange)
            .scaleEffect(cardScale)
            .onAppear {
                withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
                    displayedProgress = progress
                }
            }
            .onChange(of: count) { oldCount, newCount in
                guard newCount > oldCount else { return }
                animateIncrement(isMilestone: milestones.contains(newCount))
            }
        }
    }

    private func animateIncrement(isMilestone: Bool) {
        flameBouncing.toggle()
        withAnimation(.easeInOut(duration: 0.5).delay(0.1)) {
            displayedProgress = progress
        }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.4)) {
            cardScale = 1.06
        }
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8).delay(0.15)) {
            cardScale = 1.0
        }
        if isMilestone {
            launchParticles()
        }
    }

    private func launchParticles() {
        let colors: [Color] = [.red, .orange, .yellow, .green, .blue, .purple, .pink]
        particles = (0..<20).map { i in
            let angleDegrees = Double.random(in: 25...65)
            let distance = CGFloat.random(in: 60...110)
            let radians = angleDegrees * .pi / 180
            return StreakParticle(
                color: colors[i % colors.count],
                targetOffset: CGSize(
                    width: distance * cos(radians),
                    height: -distance * sin(radians)
                ),
                rotation: Double.random(in: 0...360),
                size: CGFloat.random(in: 5...9),
                delay: Double(i) * 0.03
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            particles = []
        }
    }
}

private struct StreakParticle: Identifiable {
    let id = UUID()
    let color: Color
    let targetOffset: CGSize
    let rotation: Double
    let size: CGFloat
    let delay: Double
}

#Preview {
    @Previewable @State var count = 2
    let milestones: Set<Int> = [3, 7, 14, 30, 60, 90, 180, 365]

    VStack(spacing: 20) {
        StreakCardView(count: count, unit: "Day", milestones: milestones)
            .padding(.horizontal)
        HStack(spacing: 16) {
            Button("Increment") { count += 1 }
                .buttonStyle(.borderedProminent)
            Button("Reset") { count = 0 }
                .buttonStyle(.bordered)
        }
        Text("Next milestones: 3, 7, 14, 30…")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
    .padding(.vertical, 40)
}

private struct StreakParticleView: View {
    let particle: StreakParticle
    @State private var active = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(particle.color)
            .frame(width: particle.size, height: particle.size)
            .rotationEffect(.degrees(active ? particle.rotation : 0))
            .offset(active ? particle.targetOffset : .zero)
            .opacity(active ? 0 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: 0.85).delay(particle.delay)) {
                    active = true
                }
            }
    }
}
