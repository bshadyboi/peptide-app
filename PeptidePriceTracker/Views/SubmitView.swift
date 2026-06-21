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
      ZStack {
        DarkAuroraBackground()

        ScrollView {
          VStack(alignment: .leading, spacing: 16) {
            if let successMessage {
              DarkFormBanner(text: successMessage, style: .success)
            }
            if let errorMessage {
              DarkFormBanner(text: errorMessage, style: .error)
            }

            DarkFormSection(title: "Peptide") {
              DarkFormPicker(
                label: "Peptide",
                selection: $selectedPeptideID,
                options: peptides.filter { $0.category == .single }.map { ($0.id, $0.name) }
              )
              .onChange(of: selectedPeptideID) { _, _ in
                selectedDoseID = doses.first?.id
              }

              if !doses.isEmpty {
                DarkFormPicker(
                  label: "Dose",
                  selection: $selectedDoseID,
                  options: doses.map { ($0.id, $0.displayName) }
                )
              }
            }

            DarkFormSection(title: "Price info") {
              DarkFormField(label: "Vendor name", text: $vendorName)
              DarkFormField(label: "Price (USD)", text: $priceText, keyboard: .decimalPad)
              DarkFormField(label: "Discount code (optional)", text: $discountCode)
            }

            Button {
              Task { await submit() }
            } label: {
              Group {
                if isSubmitting {
                  ProgressView().tint(.white)
                } else {
                  Text("Submit for review")
                    .fontWeight(.semibold)
                }
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.neonCyan)
            .disabled(!canSubmit || isSubmitting)

            Text("Submissions are reviewed before appearing in the app.")
              .font(.caption)
              .foregroundStyle(Color.white.opacity(0.45))
              .frame(maxWidth: .infinity, alignment: .center)
          }
          .padding(16)
          .padding(.bottom, 24)
        }
      }
      .navigationTitle("Submit")
      .toolbarBackground(.hidden, for: .navigationBar)
      .preferredColorScheme(.dark)
      .task {
        guard SupabaseConfig.isConfigured else { return }
        await syncService.ensureSignedIn()
        await syncService.syncCatalog(context: modelContext)
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

private enum DarkFormBannerStyle {
  case success, error
}

private struct DarkFormBanner: View {
  let text: String
  let style: DarkFormBannerStyle

  var body: some View {
    Text(text)
      .font(.subheadline)
      .foregroundStyle(style == .success ? AppTheme.inStock : AppTheme.sale)
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill((style == .success ? AppTheme.inStock : AppTheme.sale).opacity(0.12))
      }
  }
}

private struct DarkFormSection<Content: View>: View {
  let title: String
  @ViewBuilder let content: Content

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title.uppercased())
        .font(.caption.weight(.bold))
        .foregroundStyle(Color.white.opacity(0.45))
        .tracking(0.6)

      VStack(spacing: 12) {
        content
      }
      .padding(14)
      .background {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(AppTheme.darkCard.opacity(0.85))
          .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
          }
      }
    }
  }
}

private struct DarkFormField: View {
  let label: String
  @Binding var text: String
  var keyboard: UIKeyboardType = .default

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(.caption)
        .foregroundStyle(Color.white.opacity(0.55))
      TextField(label, text: $text)
        .keyboardType(keyboard)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .padding(10)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .foregroundStyle(.white)
    }
  }
}

private struct DarkFormPicker: View {
  let label: String
  @Binding var selection: UUID?
  let options: [(UUID, String)]

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(label)
        .font(.caption)
        .foregroundStyle(Color.white.opacity(0.55))
      Picker(label, selection: $selection) {
        Text("Select…").tag(UUID?.none)
        ForEach(options, id: \.0) { id, name in
          Text(name).tag(Optional(id))
        }
      }
      .pickerStyle(.menu)
      .tint(AppTheme.neonCyan)
    }
  }
}

#Preview {
  SubmitView()
    .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
    .modelContainer(for: [Peptide.self, Dose.self], inMemory: true)
}
