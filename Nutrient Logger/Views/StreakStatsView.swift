import SwiftUI

struct StreakStatsView: View {
    let title: String
    let count: Int
    let unit: String
    let longestCount: Int?
    let startDate: SimpleDate?
    let milestones: Set<Int>

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

    private var achievedMilestones: [Int] {
        sortedMilestones.filter { $0 <= count }
    }

    private var unitPlural: String { "\(unit.lowercased())s" }

    var body: some View {
        ScrollView {
            VStack(spacing: .spacingDefault) {
                VStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    Text("\(count)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundStyle(.orange)
                    Text("\(unit) Streak")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 8)

                VStack(spacing: .spacingDefault) {
                    HStack {
                        Text(title)
                            .listSectionHeader()
                        Spacer()
                    }
                    VStack(spacing: 0) {
                        if let longestCount, longestCount > 0 {
                            StatRow(icon: "trophy.fill", iconColor: .yellow, label: "Best Streak", value: "\(longestCount) \(unitPlural)")
                            Divider().padding(.horizontal)
                        }
                        if let startDate {
                            StatRow(icon: "calendar", iconColor: .blue, label: "Started", value: startDate.formatted())
                            if nextMilestone != nil {
                                Divider().padding(.horizontal)
                            }
                        }
                        if let nextMilestone {
                            VStack(spacing: 6) {
                                HStack {
                                    Image(systemName: "flag.fill")
                                        .foregroundStyle(.green)
                                        .frame(width: 20)
                                    Text("Next Milestone")
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(nextMilestone) \(unitPlural)")
                                        .font(.subheadline.bold())
                                }
                                ProgressView(value: progress)
                                    .tint(.orange)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        }
                    }
                    .padding(.vertical, 4)
                    .inCard(backgroundColor: .gray)
                }

                if !achievedMilestones.isEmpty {
                    VStack(spacing: .spacingDefault) {
                        HStack {
                            Text("Milestones Reached")
                                .listSectionHeader()
                            Spacer()
                        }
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 8) {
                            ForEach(achievedMilestones, id: \.self) { milestone in
                                MilestoneBadge(count: milestone, unit: unit)
                            }
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct StatRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 20)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

private struct MilestoneBadge: View {
    let count: Int
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            Text("\(count)")
                .font(.subheadline.bold())
            Text(unit.lowercased() + (count == 1 ? "" : "s"))
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .inCard(backgroundColor: .gray)
    }
}

#Preview {
    StreakStatsView(
        title: "Daily Logging",
        count: 14,
        unit: "Day",
        longestCount: 30,
        startDate: SimpleDate.today.adding(days: -13),
        milestones: [3, 7, 14, 30, 60, 90, 180, 365]
    )
}
