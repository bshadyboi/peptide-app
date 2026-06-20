import SwiftUI
import SwiftData

struct SubmitView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @Query(sort: \Peptide.name) private var peptides: [Peptide]

  @State private var selectedPeptideID: UUID?
  @State private var selectedDoseID: UUID?
  @State private var vendorName = ""
  @State private var priceText = ""
  @State private var discountCode = ""
  @State private var isSubmitting = false
  @State private var successMessage: String?
  @State private var errorMessage: String?

  private var selectedPeptide: Peptide? {
    peptides.first { $0.id == selectedPeptideID }
  }

  private var doses: [Dose] {
    selectedPeptide?.doses.sorted { $0.mg < $1.mg } ?? []
  }

  var body: some View {
    NavigationStack {
      Form {
        if let successMessage {
          Section {
            Text(successMessage)
              .foregroundStyle(.green)
          }
        }

        if let errorMessage {
          Section {
            Text(errorMessage)
              .foregroundStyle(.red)
          }
        }

        Section("Peptide") {
          Picker("Peptide", selection: $selectedPeptideID) {
            Text("Select…").tag(UUID?.none)
            ForEach(peptides.filter { $0.category == .single }, id: \.id) { peptide in
              Text(peptide.name).tag(Optional(peptide.id))
            }
          }
          .onChange(of: selectedPeptideID) { _, _ in
            selectedDoseID = doses.first?.id
          }

          if !doses.isEmpty {
            Picker("Dose", selection: $selectedDoseID) {
              ForEach(doses, id: \.id) { dose in
                Text(dose.displayName).tag(Optional(dose.id))
              }
            }
          }
        }

        Section("Price info") {
          TextField("Vendor name", text: $vendorName)
          TextField("Price (USD)", text: $priceText)
            .keyboardType(.decimalPad)
          TextField("Discount code (optional)", text: $discountCode)
        }

        Section {
          Button {
            Task { await submit() }
          } label: {
            if isSubmitting {
              ProgressView()
                .frame(maxWidth: .infinity)
            } else {
              Text("Submit for review")
                .frame(maxWidth: .infinity)
            }
          }
          .disabled(!canSubmit || isSubmitting)
        } footer: {
          Text("Submissions are reviewed before appearing in the app.")
        }
      }
      .navigationTitle("Submit")
      .task {
        guard SupabaseConfig.isConfigured else { return }
        await syncService.ensureSignedIn()
        if selectedPeptideID == nil {
          selectedPeptideID = peptides.first { $0.slug == "bpc-157" }?.id
          selectedDoseID = doses.first?.id
        }
      }
    }
  }

  private var canSubmit: Bool {
    selectedDoseID != nil
      && !vendorName.trimmingCharacters(in: .whitespaces).isEmpty
      && Decimal(string: priceText) != nil
  }

  private func submit() async {
    guard let doseID = selectedDoseID,
      let price = Decimal(string: priceText)
    else { return }

    isSubmitting = true
    successMessage = nil
    errorMessage = nil
    defer { isSubmitting = false }

    do {
      try await syncService.submitPrice(
        doseID: doseID,
        vendorName: vendorName.trimmingCharacters(in: .whitespaces),
        price: price,
        discountCode: discountCode
      )
      successMessage = "Thanks! Your submission is pending review."
      vendorName = ""
      priceText = ""
      discountCode = ""
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}

#Preview {
  SubmitView()
    .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
    .modelContainer(for: [Peptide.self, Dose.self], inMemory: true)
}
