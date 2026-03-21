import SwiftUI
import SwiftUI
import Charts
import SwiftData

struct AnalyticsView: View {
    @StateObject var vm = AnalyticsViewModel()
    @Environment(\.modelContext) var modelContext

    var body: some View {
        NavigationStack {
            ZStack {
                Color.fpBackground.ignoresSafeArea()
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Analytics")
                            .font(.largeTitle).fontWeight(.bold).foregroundStyle(Color.fpTextPrimary).padding(.top, 4)
                        weeklyChartCard
                        weekComparisonCard
                        statsRow
                        if !vm.topBlockedDomains.isEmpty { topBlocklistsCard }
                        totalSessionsCard
                        Spacer(minLength: 32)
                    }
                    .padding(.horizontal, 20).padding(.bottom, 20)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .task { vm.loadAnalytics(context: modelContext) }
    }

    // MARK: - Weekly Chart

    private var weeklyChartCard: some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("This Week")
                            .font(.caption).fontWeight(.semibold).foregroundStyle(Color.fpTextSecondary)
                            .textCase(.uppercase).tracking(0.5)
                        Text(vm.formattedHours(vm.thisWeekMinutes))
                            .font(.title2).fontWeight(.bold).foregroundStyle(Color.fpTextPrimary)
                    }
                    Spacer()
                    Image(systemName: "chart.bar.fill").font(.system(size: 20)).foregroundStyle(Color.fpPrimary)
                }
                Chart {
                    ForEach(vm.weeklyData) { item in
                        BarMark(x: .value("Day", item.day), y: .value("Hours", item.hours))
                            .foregroundStyle(item.hours > 0
                                ? LinearGradient.fpPrimaryGradient
                                : LinearGradient(colors: [Color.fpBorder, Color.fpBorder], startPoint: .leading, endPoint: .trailing))
                            .cornerRadius(6)
                    }
                }
                .frame(height: 180)
                .chartXAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(Color.fpTextSecondary).font(.caption) } }
                .chartYAxis { AxisMarks(position: .leading) { _ in
                    AxisValueLabel().foregroundStyle(Color.fpTextSecondary).font(.caption)
                    AxisGridLine().foregroundStyle(Color.fpBorder.opacity(0.5))
                }}
                .chartPlotStyle { $0.background(Color.clear) }
            }
        }
    }

    // MARK: - Week Comparison

    private var weekComparisonCard: some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Week Comparison")
                        .font(.caption).fontWeight(.semibold).foregroundStyle(Color.fpTextSecondary)
                        .textCase(.uppercase).tracking(0.5)
                    Spacer()
                    weekChangeBadge
                }
                HStack(spacing: 0) {
                    weekColumn(label: "This Week", minutes: vm.thisWeekMinutes,
                               maxMinutes: max(vm.thisWeekMinutes, vm.lastWeekMinutes, 1),
                               gradient: LinearGradient.fpPrimaryGradient,
                               textColor: Color.fpTextPrimary)
                    Rectangle().fill(Color.fpBorder).frame(width: 1, height: 60).padding(.horizontal, 16)
                    weekColumn(label: "Last Week", minutes: vm.lastWeekMinutes,
                               maxMinutes: max(vm.thisWeekMinutes, vm.lastWeekMinutes, 1),
                               gradient: LinearGradient(colors: [Color.fpTextSecondary.opacity(0.5), Color.fpTextSecondary.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                               textColor: Color.fpTextSecondary)
                }
            }
        }
    }

    private func weekColumn(label: String, minutes: Int, maxMinutes: Int, gradient: LinearGradient, textColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(.caption).foregroundStyle(Color.fpTextSecondary)
            Text(vm.formattedHours(minutes)).font(.title3).fontWeight(.bold).foregroundStyle(textColor)
            let fraction = min(Double(minutes) / Double(maxMinutes), 1.0)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.fpBorder).frame(height: 6)
                    RoundedRectangle(cornerRadius: 4).fill(gradient).frame(width: geo.size.width * fraction, height: 6)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var weekChangeBadge: some View {
        let pct = vm.weeklyChangePercent
        if pct != 0 || vm.lastWeekMinutes > 0 {
            HStack(spacing: 4) {
                Image(systemName: pct >= 0 ? "arrow.up" : "arrow.down").font(.caption2).fontWeight(.bold)
                Text(String(format: "%.0f%%", abs(pct))).font(.caption).fontWeight(.bold)
            }
            .foregroundStyle(pct >= 0 ? Color.fpAccent : Color.fpDanger)
            .padding(.horizontal, 10).padding(.vertical, 5)
            .background((pct >= 0 ? Color.fpAccent : Color.fpDanger).opacity(0.15))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 16) {
            AnalyticsCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "flame.fill").font(.system(size: 20))
                            .foregroundStyle(LinearGradient(colors: [Color(red:1,green:0.5,blue:0.1), Color(red:1,green:0.3,blue:0)], startPoint: .top, endPoint: .bottom))
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text("\(vm.longestStreak)").font(.title2).fontWeight(.bold).foregroundStyle(Color.fpTextPrimary)
                            Text("days").font(.caption).foregroundStyle(Color.fpTextSecondary)
                        }
                        Text("Longest Streak").font(.caption).foregroundStyle(Color.fpTextSecondary)
                    }
                }
            }
            AnalyticsCard {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "clock.fill").font(.system(size: 20)).foregroundStyle(Color.fpAccent)
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(vm.formattedHour(vm.mostProductiveHour)).font(.title2).fontWeight(.bold).foregroundStyle(Color.fpTextPrimary)
                        Text("Peak Hour").font(.caption).foregroundStyle(Color.fpTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Top Blocklists

    private var topBlocklistsCard: some View {
        AnalyticsCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Most Used Blocklists")
                        .font(.caption).fontWeight(.semibold).foregroundStyle(Color.fpTextSecondary)
                        .textCase(.uppercase).tracking(0.5)
                    Spacer()
                    Image(systemName: "shield.fill").font(.system(size: 16)).foregroundStyle(Color.fpPrimary)
                }
                VStack(spacing: 10) {
                    ForEach(Array(vm.topBlockedDomains.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(index == 0 ? LinearGradient.fpPrimaryGradient : LinearGradient(colors: [Color.fpBorder, Color.fpBorder], startPoint: .leading, endPoint: .trailing))
                                    .frame(width: 28, height: 28)
                                Text("\(index + 1)").font(.caption2).fontWeight(.bold)
                                    .foregroundStyle(index == 0 ? .white : Color.fpTextSecondary)
                            }
                            Text(item.domain.isEmpty ? "Unknown" : item.domain)
                                .font(.subheadline).foregroundStyle(Color.fpTextPrimary).lineLimit(1).truncationMode(.tail)
                            Spacer()
                            Text("\(item.count)").font(.caption).fontWeight(.bold).foregroundStyle(.white)
                                .padding(.horizontal, 10).padding(.vertical, 4)
                                .background(Color.fpPrimary).clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        if index < vm.topBlockedDomains.count - 1 { Divider().background(Color.fpBorder) }
                    }
                }
            }
        }
    }

    // MARK: - Total Sessions

    private var totalSessionsCard: some View {
        AnalyticsCard {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12).fill(LinearGradient.fpPrimaryGradient).frame(width: 48, height: 48)
                    Image(systemName: "checkmark.seal.fill").font(.system(size: 22)).foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(vm.totalSessionsAllTime)").font(.title2).fontWeight(.bold).foregroundStyle(Color.fpTextPrimary)
                    Text("Total Sessions Completed").font(.subheadline).foregroundStyle(Color.fpTextSecondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Card Container

private struct AnalyticsCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }
    var body: some View {
        content().padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.fpSurface)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.fpBorder, lineWidth: 1)))
    }
}
