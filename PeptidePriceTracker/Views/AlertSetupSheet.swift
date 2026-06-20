import SwiftUI

struct AlertSetupSheet: View {
  let dose: Dose
  let suggestedTarget: Decimal?

  @EnvironmentObject private var syncService: DataSyncService
  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

  @State private var targetText = ""
  @State private var isSaving = false
  @State private var errorMessage: String?

  var body: some View {
    NavigationStack {
      Form {
        Section {
          Text(dose.peptide?.name ?? "Peptide")
            .font(.headline)
          Text(dose.displayName)
            .foregroundStyle(.secondary)
        }

        Section("Target price per mg") {
          TextField("e.g. 8.50", text: $targetText)
            .keyboardType(.decimalPad)

          if let suggestedTarget {
            Button("Use current best: \(CurrencyFormatter.formatPerMg(suggestedTarget))") {
              targetText = formatInput(suggestedTarget)
            }
            .font(.caption)
          }
        }

        if let errorMessage {
          Section {
            Text(errorMessage)
              .foregroundStyle(.red)
              .font(.caption)
          }
        }

        Section {
          Button {
            Task { await save() }
          } label: {
            if isSaving {
              ProgressView()
                .frame(maxWidth: .infinity)
            } else {
              Text("Save alert")
                .frame(maxWidth: .infinity)
            }
          }
          .disabled(targetDecimal == nil || isSaving)
        } footer: {
          Text("You'll get a push when the best in-stock price drops to or below this $/mg.")
        }
      }
      .navigationTitle("Alert me")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") { dismiss() }
        }
      }
      .onAppear {
        if targetText.isEmpty, let suggestedTarget {
          targetText = formatInput(suggestedTarget)
        }
      }
      .task {
        await syncService.ensureSignedIn()
      }
    }
  }

  private var targetDecimal: Decimal? {
    Decimal(string: targetText)
  }

  private func formatInput(_ value: Decimal) -> String {
    let number = NSDecimalNumber(decimal: value)
    return String(format: "%.2f", number.doubleValue)
  }

  private func save() async {
    guard let target = targetDecimal else { return }
    isSaving = true
    errorMessage = nil
    defer { isSaving = false }

    do {
      try await syncService.createAlert(
        doseID: dose.id,
        targetPerMg: target,
        context: modelContext
      )
      dismiss()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
