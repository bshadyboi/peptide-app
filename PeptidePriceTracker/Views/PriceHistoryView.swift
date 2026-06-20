import Charts
import SwiftData
import SwiftUI

private struct HistoryChartPoint: Identifiable {
  let id: UUID
  let capturedAt: Date
  let pricePerMg: Double
  let vendorName: String
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
          Text("Price history builds automatically after the daily snapshot job runs. Pull to refresh once snapshots exist.")
        }
        Spacer()
      } else {
        Chart(chartPoints) { point in
          LineMark(
            x: .value("Date", point.capturedAt),
            y: .value("Price per mg", point.pricePerMg)
          )
          .foregroundStyle(by: .value("Vendor", point.vendorName))
          .interpolationMethod(.catmullRom)
        }
        .chartYAxisLabel("$/mg")
        .chartXAxis {
          AxisMarks(values: .automatic) { _ in
            AxisGridLine()
            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
          }
        }
        .padding()

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
}

#Preview {
  let dose = Dose(mg: 5)
  return NavigationStack {
    PriceHistoryView(dose: dose)
      .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
  }
  .modelContainer(for: [PricePoint.self, Dose.self, Vendor.self], inMemory: true)
}
