import SwiftUI
import SwiftData

struct VendorsListSheet: View {
  @Query(sort: \Vendor.name) private var vendors: [Vendor]
  @Query private var prices: [Price]

  @Binding var selectedVendorFilterID: UUID?

  private var liveVendors: [LiveVendorSummary] {
    VendorCatalog.liveVendors(from: vendors, prices: prices)
  }

  var body: some View {
    NavigationStack {
      Group {
        if liveVendors.isEmpty {
          ContentUnavailableView {
            Label("No Vendors Yet", systemImage: "building.2")
          } description: {
            Text("Pull to refresh on Home after scrapers run. Vendors appear here once they have in-stock prices.")
          }
        } else {
          List {
            Section {
              Button {
                selectedVendorFilterID = nil
              } label: {
                HStack {
                  Text("All vendors")
                    .foregroundStyle(.primary)
                  Spacer()
                  if selectedVendorFilterID == nil {
                    Image(systemName: "checkmark")
                      .foregroundStyle(AppTheme.accent)
                  }
                }
              }
            }

            Section("\(liveVendors.count) with prices") {
              ForEach(liveVendors) { summary in
                Button {
                  selectedVendorFilterID = summary.vendor.id
                } label: {
                  VendorRow(summary: summary, isSelected: selectedVendorFilterID == summary.vendor.id)
                }
              }
            }
          }
          .listStyle(.insetGrouped)
        }
      }
      .navigationTitle("Suppliers")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done") {
            dismissSheet()
          }
        }
      }
    }
  }

  @Environment(\.dismiss) private var dismiss

  private func dismissSheet() {
    dismiss()
  }
}

private struct VendorRow: View {
  let summary: LiveVendorSummary
  let isSelected: Bool

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 2) {
        Text(summary.name)
          .font(.body)
          .foregroundStyle(.primary)
        if let url = summary.vendor.url, let host = URL(string: url)?.host {
          Text(host)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      Spacer()

      Text("\(summary.inStockPriceCount)")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemFill))
        .clipShape(Capsule())

      if isSelected {
        Image(systemName: "checkmark")
          .foregroundStyle(AppTheme.accent)
      }
    }
  }
}

#Preview {
  VendorsListSheet(selectedVendorFilterID: .constant(nil))
    .modelContainer(for: [Vendor.self, Price.self], inMemory: true)
}
