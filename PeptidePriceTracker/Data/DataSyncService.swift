import Foundation
import SwiftData

@MainActor
final class DataSyncService: ObservableObject {
  @Published private(set) var isSyncing = false
  @Published private(set) var lastError: String?

  private let api: APIClient?
  let authSession: AuthSession

  init(api: APIClient?, authSession: AuthSession) {
    self.api = api
    self.authSession = authSession
  }

  private var catalogSyncTask: Task<Void, Never>?
  private var catalogSyncGeneration = 0

  /// Full catalog sync: peptides, doses, vendors, prices → SwiftData.
  func syncCatalog(context: ModelContext) async {
    guard let api else {
      lastError = APIError.notConfigured.errorDescription
      return
    }

    let previous = catalogSyncTask
    catalogSyncGeneration += 1
    let generation = catalogSyncGeneration
    isSyncing = true
    lastError = nil

    let task = Task { @MainActor in
      if let previous { await previous.value }
      await performCatalogSync(api: api, context: context)
    }
    catalogSyncTask = task
    await task.value

    if generation == catalogSyncGeneration {
      catalogSyncTask = nil
      isSyncing = false
    }
  }

  private func performCatalogSync(api: APIClient, context: ModelContext) async {
    var errors: [String] = []

    do {
      let peptides = try await api.fetchPeptides(category: nil)
      for dto in peptides {
        upsertPeptide(dto, context: context)
      }
      try context.save()
    } catch {
      appendSyncError(&errors, label: "Peptides", error: error)
    }

    do {
      let vendors = try await api.fetchAllVendors()
      for dto in vendors {
        upsertVendor(dto, context: context)
      }
      try context.save()
    } catch {
      appendSyncError(&errors, label: "Vendors", error: error)
    }

    do {
      let prices = try await api.fetchAllPrices()
      for dto in prices {
        upsertPrice(dto, context: context)
      }
      try context.save()
    } catch {
      appendSyncError(&errors, label: "Prices", error: error)
    }

    if !errors.isEmpty {
      lastError = errors.joined(separator: "\n")
    }
  }

  private func appendSyncError(_ errors: inout [String], label: String, error: Error) {
    if Self.isBenignCancellation(error) { return }
    errors.append("\(label): \(error.localizedDescription)")
  }

  private static func isBenignCancellation(_ error: Error) -> Bool {
    if error is CancellationError { return true }
    if let urlError = error as? URLError, urlError.code == .cancelled { return true }
    let nsError = error as NSError
    return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled
  }

  /// Refresh prices for a single dose (detail screen).
  func syncPrices(for doseID: UUID, context: ModelContext) async {
    guard let api else { return }
    do {
      let prices = try await api.fetchPrices(forDose: doseID)
      for dto in prices {
        if let vendor = dto.vendors {
          upsertVendor(vendor, context: context)
        }
        upsertPrice(dto, context: context)
      }
      try context.save()
    } catch {
      if !Self.isBenignCancellation(error) {
        lastError = error.localizedDescription
      }
    }
  }

  /// Fetch price_history for a dose and cache in SwiftData.
  func syncHistory(for doseID: UUID, range: HistoryRange, context: ModelContext) async {
    guard let api else { return }
    do {
      let rows = try await api.fetchPriceHistory(forDose: doseID, range: range)
      let since = range.startDate
      let existing = try context.fetch(FetchDescriptor<PricePoint>())
      for point in existing where point.doseId == doseID && point.capturedAt >= since {
        context.delete(point)
      }
      for dto in rows {
        upsertPricePoint(dto, context: context)
      }
      try context.save()
    } catch {
      lastError = error.localizedDescription
    }
  }

  func ensureSignedIn() async {
    await authSession.signInIfNeeded()
  }

  func syncAlerts(context: ModelContext) async {
    guard let api, let token = authSession.accessToken else { return }
    do {
      let rows = try await api.fetchAlerts(accessToken: token)
      let remoteIDs = Set(rows.map(\.id))
      let existing = try context.fetch(FetchDescriptor<PriceAlert>())
      for alert in existing where !remoteIDs.contains(alert.id) {
        context.delete(alert)
      }
      for dto in rows {
        upsertAlert(dto, context: context)
      }
      try context.save()
    } catch {
      lastError = error.localizedDescription
    }
  }

  func createAlert(doseID: UUID, targetPerMg: Decimal, context: ModelContext) async throws {
    guard let api, let token = authSession.accessToken else {
      throw APIError.notConfigured
    }
    let dto = try await api.createAlert(doseID: doseID, targetPerMg: targetPerMg, accessToken: token)
    upsertAlert(dto, context: context)
    try context.save()
  }

  func deleteAlert(id: UUID, context: ModelContext) async throws {
    guard let api, let token = authSession.accessToken else {
      throw APIError.notConfigured
    }
    try await api.deleteAlert(id: id, accessToken: token)
    if let existing = fetchAlert(id: id, context: context) {
      context.delete(existing)
      try context.save()
    }
  }

  func submitPrice(
    doseID: UUID,
    vendorName: String,
    price: Decimal,
    discountCode: String?
  ) async throws {
    guard let api, let token = authSession.accessToken else {
      throw APIError.notConfigured
    }
    try await api.submitPrice(
      doseID: doseID,
      vendorName: vendorName,
      price: price,
      discountCode: discountCode,
      accessToken: token
    )
  }

  // MARK: - Upsert

  private func upsertPeptide(_ dto: PeptideDTO, context: ModelContext) {
    let peptide: Peptide
    if let existing = fetchPeptide(id: dto.id, context: context) {
      peptide = existing
    } else {
      peptide = Peptide(
        id: dto.id,
        name: dto.name,
        slug: dto.slug,
        category: PeptideCategory(rawValue: dto.category) ?? .single,
        aliases: dto.aliases ?? [],
        description: dto.description,
        createdAt: dto.createdAt ?? .now
      )
      context.insert(peptide)
    }

    peptide.name = dto.name
    peptide.slug = dto.slug
    peptide.category = PeptideCategory(rawValue: dto.category) ?? .single
    peptide.aliases = dto.aliases ?? []
    peptide.peptideDescription = dto.description
    if let createdAt = dto.createdAt { peptide.createdAt = createdAt }

    for doseDTO in dto.doses ?? [] {
      let dose: Dose
      if let existing = fetchDose(id: doseDTO.id, context: context) {
        dose = existing
      } else {
        dose = Dose(id: doseDTO.id, mg: doseDTO.mg.value, label: doseDTO.label, peptide: peptide)
        context.insert(dose)
      }
      dose.mg = doseDTO.mg.value
      dose.label = doseDTO.label
      dose.peptide = peptide
      if !peptide.doses.contains(where: { $0.id == dose.id }) {
        peptide.doses.append(dose)
      }
    }

    let remoteComponentIDs = Set((dto.blendComponents ?? []).map(\.id))
    for existing in peptide.blendComponents where !remoteComponentIDs.contains(existing.id) {
      context.delete(existing)
    }
    for componentDTO in dto.blendComponents ?? [] {
      guard let component = componentDTO.component else { continue }
      let row: BlendComponent
      if let existing = fetchBlendComponent(id: componentDTO.id, context: context) {
        row = existing
      } else {
        row = BlendComponent(
          id: componentDTO.id,
          blendId: dto.id,
          componentName: component.name,
          componentSlug: component.slug,
          mg: componentDTO.mg.value,
          peptide: peptide
        )
        context.insert(row)
      }
      row.blendId = dto.id
      row.componentName = component.name
      row.componentSlug = component.slug
      row.mg = componentDTO.mg.value
      row.peptide = peptide
      if !peptide.blendComponents.contains(where: { $0.id == row.id }) {
        peptide.blendComponents.append(row)
      }
    }
  }

  private func upsertVendor(_ dto: VendorDTO, context: ModelContext) {
    let vendor: Vendor
    if let existing = fetchVendor(id: dto.id, context: context) {
      vendor = existing
    } else {
      vendor = Vendor(id: dto.id, name: dto.name, url: dto.url, shipsFrom: dto.shipsFrom, notes: dto.notes)
      context.insert(vendor)
    }
    vendor.name = dto.name
    vendor.url = dto.url
    vendor.shipsFrom = dto.shipsFrom
    vendor.notes = dto.notes
    vendor.isActive = dto.isActive ?? true
  }

  private func upsertPrice(_ dto: PriceDTO, context: ModelContext) {
    let dose: Dose
    if let existing = fetchDose(id: dto.doseId, context: context) {
      dose = existing
    } else {
      dose = Dose(id: dto.doseId, mg: 0)
      context.insert(dose)
    }

    let vendor: Vendor
    if let existing = fetchVendor(id: dto.vendorId, context: context) {
      vendor = existing
    } else {
      vendor = Vendor(id: dto.vendorId, name: dto.vendors?.name ?? "Unknown")
      context.insert(vendor)
    }
    if let embedded = dto.vendors {
      vendor.name = embedded.name
      vendor.url = embedded.url
      vendor.shipsFrom = embedded.shipsFrom
      vendor.notes = embedded.notes
      vendor.isActive = embedded.isActive ?? true
    }

    let price: Price
    if let existing = fetchPrice(id: dto.id, context: context) {
      price = existing
    } else {
      price = Price(id: dto.id, price: dto.price.value, dose: dose, vendor: vendor)
      context.insert(price)
    }

    price.price = dto.price.value
    price.salePrice = dto.salePrice?.value
    price.currency = dto.currency ?? "USD"
    price.inStock = dto.inStock ?? true
    price.discountCode = dto.discountCode
    price.coaAvailable = dto.coaAvailable ?? false
    price.productUrl = dto.productUrl
    price.source = PriceSource(rawValue: dto.source) ?? .manual
    if let lastSeen = dto.lastSeenAt { price.lastSeenAt = lastSeen }
    if let createdAt = dto.createdAt { price.createdAt = createdAt }
    price.dose = dose
    price.vendor = vendor

    if !dose.prices.contains(where: { $0.id == price.id }) {
      dose.prices.append(price)
    }
  }

  private func upsertPricePoint(_ dto: PriceHistoryDTO, context: ModelContext) {
    let dose: Dose
    if let existing = fetchDose(id: dto.doseId, context: context) {
      dose = existing
    } else {
      dose = Dose(id: dto.doseId, mg: 0)
      context.insert(dose)
    }

    let vendor: Vendor
    if let existing = fetchVendor(id: dto.vendorId, context: context) {
      vendor = existing
    } else {
      vendor = Vendor(id: dto.vendorId, name: dto.vendors?.name ?? "Unknown")
      context.insert(vendor)
    }
    if let name = dto.vendors?.name {
      vendor.name = name
    }

    let point: PricePoint
    if let existing = fetchPricePoint(id: dto.id, context: context) {
      point = existing
    } else {
      point = PricePoint(id: dto.id, doseId: dto.doseId, vendorId: dto.vendorId, price: dto.price.value, dose: dose, vendor: vendor)
      context.insert(point)
    }

    point.doseId = dto.doseId
    point.vendorId = dto.vendorId
    point.price = dto.price.value
    point.pricePerMg = dto.pricePerMg?.value
    point.capturedAt = dto.capturedAt
    point.dose = dose
    point.vendor = vendor

    if !dose.pricePoints.contains(where: { $0.id == point.id }) {
      dose.pricePoints.append(point)
    }
  }

  private func upsertAlert(_ dto: AlertDTO, context: ModelContext) {
    let dose: Dose
    if let existing = fetchDose(id: dto.doseId, context: context) {
      dose = existing
    } else {
      dose = Dose(id: dto.doseId, mg: 0)
      context.insert(dose)
    }

    let alert: PriceAlert
    if let existing = fetchAlert(id: dto.id, context: context) {
      alert = existing
    } else {
      alert = PriceAlert(id: dto.id, doseId: dto.doseId, targetPerMg: dto.targetPerMg.value, dose: dose)
      context.insert(alert)
    }

    alert.doseId = dto.doseId
    alert.targetPerMg = dto.targetPerMg.value
    alert.active = dto.active ?? true
    alert.lastFiredAt = dto.lastFiredAt
    if let createdAt = dto.createdAt { alert.createdAt = createdAt }
    alert.dose = dose

    if !dose.alerts.contains(where: { $0.id == alert.id }) {
      dose.alerts.append(alert)
    }
  }

  // MARK: - Fetch by ID

  private func fetchPeptide(id: UUID, context: ModelContext) -> Peptide? {
    let descriptor = FetchDescriptor<Peptide>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }

  private func fetchDose(id: UUID, context: ModelContext) -> Dose? {
    let descriptor = FetchDescriptor<Dose>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }

  private func fetchVendor(id: UUID, context: ModelContext) -> Vendor? {
    let descriptor = FetchDescriptor<Vendor>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }

  private func fetchPrice(id: UUID, context: ModelContext) -> Price? {
    let descriptor = FetchDescriptor<Price>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }

  private func fetchPricePoint(id: UUID, context: ModelContext) -> PricePoint? {
    let descriptor = FetchDescriptor<PricePoint>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }

  private func fetchAlert(id: UUID, context: ModelContext) -> PriceAlert? {
    let descriptor = FetchDescriptor<PriceAlert>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }

  private func fetchBlendComponent(id: UUID, context: ModelContext) -> BlendComponent? {
    let descriptor = FetchDescriptor<BlendComponent>(predicate: #Predicate { $0.id == id })
    return try? context.fetch(descriptor).first
  }
}
