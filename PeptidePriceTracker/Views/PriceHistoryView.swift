import Charts
import SwiftData
import SwiftUI

private struct HistoryChartPoint: Identifiable {
  let id: UUID
  let capturedAt: Date
  let pricePerMg: Double
  let vendorName: String
}

private struct DailyBestPoint: Identifiable {
  let id: Date
  let date: Date
  let pricePerMg: Double
}

struct PriceHistoryView: View {
  let dose: Dose

  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @State private var range: HistoryRange = .days30

  @Query private var points: [PricePoint]

  init(dose: Dose) {
    self.dose = dose
    let doseID = dose.id
    _points = Query(
      filter: #Predicate<PricePoint> { $0.doseId == doseID },
      sort: \PricePoint.capturedAt
    )
  }

  private var chartPoints: [HistoryChartPoint] {
    let since = range.startDate
    return points
      .filter { $0.capturedAt >= since }
      .compactMap { point -> HistoryChartPoint? in
        guard let ppm = point.pricePerMg else { return nil }
        return HistoryChartPoint(
          id: point.id,
          capturedAt: point.capturedAt,
          pricePerMg: NSDecimalNumber(decimal: ppm).doubleValue,
          vendorName: point.vendor?.name ?? "Vendor"
        )
      }
  }

  private var dailyBestPoints: [DailyBestPoint] {
    let daily = PriceHistoryAnalytics.dailyBestPrices(from: points.filter { $0.capturedAt >= range.startDate })
    return daily.map { row in
      DailyBestPoint(
        id: row.date,
        date: row.date,
        pricePerMg: NSDecimalNumber(decimal: row.pricePerMg).doubleValue
      )
    }
  }

  private var historicalLow: Double? {
    dailyBestPoints.map(\.pricePerMg).min()
  }

  private var currentBest: Decimal? {
    Price.sortedForCompare(dose.prices).first(where: \.inStock)?.pricePerMg
  }

  private var trend: PriceTrend {
    PriceHistoryAnalytics.trend(
      for: dose.id,
      currentBestPerMg: currentBest,
      points: points,
      lookbackDays: range == .days30 ? 30 : range == .days90 ? 90 : 365
    )
  }

  private var daysUntilUseful: Int {
    max(0, 3 - (trend.daysOfHistory ?? 0))
  }

  private var vendorNames: [String] {
    Array(Set(chartPoints.map(\.vendorName))).sorted()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      Picker("Range", selection: $range) {
        ForEach(HistoryRange.allCases) { item in
          Text(item.label).tag(item)
        }
      }
      .pickerStyle(.segmented)
      .padding(.horizontal)

      if !chartPoints.isEmpty {
        historyStatsHeader
      }

      if syncService.isSyncing, chartPoints.isEmpty {
        Spacer()
        ProgressView("Loading history…")
          .frame(maxWidth: .infinity)
        Spacer()
      } else if chartPoints.isEmpty {
        Spacer()
        ContentUnavailableView {
          Label("No History Yet", systemImage: "chart.xyaxis.line")
        } description: {
          if daysUntilUseful > 0 {
            Text("Snapshots run daily at 3am UTC. Check back in about \(daysUntilUseful) day\(daysUntilUseful == 1 ? "" : "s") for trend data.")
          } else {
            Text("Price history builds automatically after the daily snapshot job runs. Pull to refresh.")
          }
        }
        Spacer()
      } else {
        Chart {
          ForEach(chartPoints) { point in
            LineMark(
              x: .value("Date", point.capturedAt),
              y: .value("Price per mg", point.pricePerMg)
            )
            .foregroundStyle(by: .value("Vendor", point.vendorName))
            .interpolationMethod(.catmullRom)
            .opacity(0.45)
          }

          ForEach(dailyBestPoints) { point in
            LineMark(
              x: .value("Date", point.date),
              y: .value("Best market", point.pricePerMg)
            )
            .foregroundStyle(AppTheme.inStock)
            .lineStyle(StrokeStyle(lineWidth: 2.5))
            .interpolationMethod(.catmullRom)
          }

          if let historicalLow {
            RuleMark(y: .value("Lowest ever", historicalLow))
              .foregroundStyle(AppTheme.accent.opacity(0.35))
              .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
              .annotation(position: .top, alignment: .trailing) {
                Text("Low \(CurrencyFormatter.formatPerMg(Decimal(historicalLow)))")
                  .font(.caption2)
                  .foregroundStyle(.secondary)
              }
          }
        }
        .chartYAxisLabel("$/mg")
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisGridLine()
            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
          }
        }
        .padding()

        HStack(spacing: 8) {
          Circle().fill(AppTheme.inStock).frame(width: 8, height: 8)
          Text("Best market $/mg")
            .font(.caption)
            .foregroundStyle(.secondary)
          Spacer()
          PriceDropBadge(trend: trend)
        }
        .padding(.horizontal)

        if !vendorNames.isEmpty {
          VStack(alignment: .leading, spacing: 8) {
            Text("Vendors")
              .font(.caption)
              .fontWeight(.semibold)
              .foregroundStyle(.secondary)
              .textCase(.uppercase)
            ForEach(vendorNames, id: \.self) { name in
              Text(name)
                .font(.caption)
            }
          }
          .padding(.horizontal)
        }
      }
    }
    .background(Color(.systemGroupedBackground))
    .navigationTitle(dose.displayName)
    .navigationBarTitleDisplayMode(.inline)
    .task(id: range) {
      await syncService.syncHistory(for: dose.id, range: range, context: modelContext)
    }
    .refreshable {
      await syncService.syncHistory(for: dose.id, range: range, context: modelContext)
    }
  }

  private var historyStatsHeader: some View {
    HStack(spacing: 16) {
      if let currentBest {
        VStack(alignment: .leading, spacing: 2) {
          Text("Current best")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text(CurrencyFormatter.formatPerMg(currentBest))
            .font(.headline)
            .foregroundStyle(AppTheme.inStock)
            .monospacedDigit()
        }
      }

      if let historicalLow {
        VStack(alignment: .leading, spacing: 2) {
          Text("Period low")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text(CurrencyFormatter.formatPerMg(Decimal(historicalLow)))
            .font(.headline)
            .monospacedDigit()
        }
      }

      Spacer()

      if let days = trend.daysOfHistory {
        VStack(alignment: .trailing, spacing: 2) {
          Text("Tracking")
            .font(.caption2)
            .foregroundStyle(.secondary)
          Text("\(days)d")
            .font(.headline)
            .monospacedDigit()
        }
      }
    }
    .padding(.horizontal)
  }
}

#Preview {
  let dose = Dose(mg: 5)
  return NavigationStack {
    PriceHistoryView(dose: dose)
      .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
  }
  .modelContainer(for: [PricePoint.self, Dose.self, Vendor.self], inMemory: true)
}
