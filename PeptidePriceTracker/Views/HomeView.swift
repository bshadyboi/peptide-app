import SwiftUI
import SwiftData

struct HomeView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @Query(sort: \Peptide.name) private var allPeptides: [Peptide]
  @Query(sort: \Vendor.name) private var allVendors: [Vendor]
  @Query private var allPrices: [Price]
  @Query private var allPricePoints: [PricePoint]

  @State private var searchText = ""
  @State private var selectedTab: PeptideCategory = .single
  @State private var displayMode: PriceDisplayMode = .perMg
  @State private var sortOption: PeptideSortOption = .popularity
  @State private var selectedTopic: PeptideTopic = .all
  @State private var selectedVendorFilterID: UUID?
  @State private var dealsOnly = false
  @State private var showVendorsSheet = false
  @State private var browsePeptideID: UUID?

  private var liveVendorCount: Int {
    VendorCatalog.liveVendors(from: allVendors, prices: allPrices).count
  }

  private var filteredPeptides: [Peptide] {
    let base = allPeptides
      .filter { $0.category == selectedTab }
      .filter { !PeptideCatalog.hiddenFromBrowseSlugs.contains($0.slug) }
      .filter { peptide in
        selectedTopic == .all || PeptideCatalog.topic(for: peptide.slug) == selectedTopic
      }
      .filter { peptide in
        guard let vendorID = selectedVendorFilterID else { return true }
        return VendorCatalog.peptideHasInStockPrice(from: vendorID, peptide: peptide)
      }
      .filter { peptide in
        guard dealsOnly else { return true }
        return PeptideDeals.hasActiveDeal(peptide)
      }
      .filter { peptide in
        guard !searchText.isEmpty else { return true }
        let query = searchText.lowercased()
        if peptide.name.lowercased().contains(query) { return true }
        if peptide.slug.lowercased().contains(query) { return true }
        return peptide.aliases.contains { $0.lowercased().contains(query) }
      }
    return sorted(base)
  }

  private var trendingPeptides: [Peptide] {
    PeptideCatalog.popularSlugs.compactMap { slug in
      allPeptides.first { $0.slug == slug }
    }
    .prefix(8)
    .map { $0 }
  }

  var body: some View {
    NavigationStack {
      Group {
        if !SupabaseConfig.isConfigured {
          configurationPrompt
        } else {
          mainContent
        }
      }
      .background(AppTheme.pageBackground)
      .navigationTitle("Compare")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            showVendorsSheet = true
          } label: {
            Label("Suppliers", systemImage: "building.2")
          }
          .accessibilityLabel("Suppliers, \(liveVendorCount) with prices")
        }
      }
      .searchable(text: $searchText, prompt: "Search peptides")
      .task {
        guard SupabaseConfig.isConfigured else { return }
        await syncService.syncCatalog(context: modelContext)
      }
      .refreshable {
        guard SupabaseConfig.isConfigured else { return }
        await syncService.syncCatalog(context: modelContext)
      }
      .sheet(isPresented: $showVendorsSheet) {
        VendorsListSheet(selectedVendorFilterID: $selectedVendorFilterID)
      }
      .navigationDestination(item: $browsePeptideID) { peptideID in
        if let peptide = allPeptides.first(where: { $0.id == peptideID }) {
          PeptideDetailView(peptide: peptide)
        }
      }
    }
  }

  private var configurationPrompt: some View {
    ContentUnavailableView {
      Label("Supabase Not Configured", systemImage: "key.slash")
    } description: {
      Text("Copy Secrets.xcconfig.example to Secrets.xcconfig and add your project URL and anon key.")
    }
  }

  private var mainContent: some View {
    List {
      if searchText.isEmpty {
        Section {
          HomeHeroBanner(
            vendorCount: liveVendorCount,
            peptideCount: allPeptides.count
          )
          .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
        }

        Section {
          ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
              ForEach(PeptideTopic.allCases) { topic in
                TopicExploreTile(
                  topic: topic,
                  isSelected: selectedTopic == topic,
                  action: { selectedTopic = topic }
                )
              }
            }
            .padding(.vertical, 4)
          }
          .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
        } header: {
          Text("Browse by goal")
        }

        if !trendingPeptides.isEmpty {
          Section {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 10) {
                ForEach(trendingPeptides, id: \.id) { peptide in
                  Button {
                    browsePeptideID = peptide.id
                  } label: {
                    TrendingPeptideCard(peptide: peptide)
                  }
                  .buttonStyle(.plain)
                }
              }
              .padding(.vertical, 4)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
          } header: {
            Text("Trending")
          }
        }
      }

      Section {
        filterControls
          .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
      }

      if let error = syncService.lastError {
        Section {
          Text(error)
            .font(.caption)
            .foregroundStyle(.red)
        }
      }

      Section {
        if syncService.isSyncing, filteredPeptides.isEmpty {
          HStack {
            Spacer()
            ProgressView("Loading…")
            Spacer()
          }
          .padding(.vertical, 32)
          .listRowBackground(Color.clear)
        } else if filteredPeptides.isEmpty {
          emptyState
            .listRowBackground(Color.clear)
        } else {
          ForEach(filteredPeptides, id: \.id) { peptide in
            NavigationLink {
              PeptideDetailView(peptide: peptide)
            } label: {
              PeptideListRow(
                peptide: peptide,
                displayMode: displayMode,
                trend: trend(for: peptide)
              )
            }
          }
        }
      } header: {
        listSectionHeader
      }
    }
    .listStyle(.plain)
    .overlay {
      if syncService.isSyncing, !filteredPeptides.isEmpty {
        ProgressView()
          .padding(8)
          .background(.ultraThinMaterial)
          .clipShape(Capsule())
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
          .padding()
      }
    }
  }

  private var listSectionHeader: some View {
    HStack {
      Text("\(filteredPeptides.count) peptide\(filteredPeptides.count == 1 ? "" : "s")")
      Spacer()
      if selectedVendorFilterID != nil {
        Button("Clear supplier") {
          selectedVendorFilterID = nil
        }
        .font(.caption)
      }
    }
  }

  private var filterControls: some View {
    VStack(spacing: 12) {
      Picker("Category", selection: $selectedTab) {
        Text("Singles").tag(PeptideCategory.single)
        Text("Blends").tag(PeptideCategory.blend)
      }
      .pickerStyle(.segmented)

      if searchText.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(PeptideTopic.allCases) { topic in
              TopicFilterChip(
                topic: topic,
                isSelected: selectedTopic == topic,
                action: { selectedTopic = topic }
              )
            }
          }
        }
      }

      HStack {
        Toggle(isOn: $dealsOnly) {
          Label("Deals", systemImage: "tag.fill")
            .font(.caption)
            .fontWeight(.medium)
        }
        .toggleStyle(.button)
        .tint(dealsOnly ? AppTheme.sale : .secondary)

        Menu {
          Picker("Sort", selection: $sortOption) {
            ForEach(PeptideSortOption.allCases, id: \.self) { option in
              Text(option.rawValue).tag(option)
            }
          }
        } label: {
          Label(sortOption.rawValue, systemImage: "arrow.up.arrow.down")
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(.secondary)
        }

        Spacer()

        Picker("Show", selection: $displayMode) {
          ForEach(PriceDisplayMode.allCases, id: \.self) { mode in
            Text(mode.rawValue).tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 150)
      }
    }
  }

  private var emptyState: some View {
    Group {
      if !searchText.isEmpty {
        ContentUnavailableView.search(text: searchText)
      } else if syncService.lastError != nil {
        ContentUnavailableView {
          Label("Sync Failed", systemImage: "exclamationmark.triangle")
        } description: {
          if let error = syncService.lastError {
            Text(error)
          }
        } actions: {
          Button("Retry") {
            Task { await syncService.syncCatalog(context: modelContext) }
          }
          .buttonStyle(.borderedProminent)
        }
      } else {
        ContentUnavailableView {
          Label("No Peptides Loaded", systemImage: "pills")
        } description: {
          Text("Pull down to refresh, or tap Retry to fetch the catalog from Supabase.")
        } actions: {
          Button("Retry") {
            Task { await syncService.syncCatalog(context: modelContext) }
          }
          .buttonStyle(.borderedProminent)
        }
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 24)
  }

  private func trend(for peptide: Peptide) -> PriceTrend? {
    guard let dose = peptide.defaultDose else { return nil }
    let currentBest = Price.sortedForCompare(dose.prices).first(where: \.inStock)?.pricePerMg
    let result = PriceHistoryAnalytics.trend(
      for: dose.id,
      currentBestPerMg: currentBest,
      points: allPricePoints
    )
    guard result.changePercent != nil || result.isLowestEver else { return nil }
    return result
  }

  private func sorted(_ peptides: [Peptide]) -> [Peptide] {
    switch sortOption {
    case .name:
      return peptides.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    case .popularity:
      return peptides.sorted {
        PeptideCatalog.popularityRank(for: $0.slug) < PeptideCatalog.popularityRank(for: $1.slug)
      }
    case .price:
      return peptides.sorted {
        ($0.bestPricePerMg ?? .sortSentinel) < ($1.bestPricePerMg ?? .sortSentinel)
      }
    }
  }
}

#Preview {
  HomeView()
    .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
    .modelContainer(for: [Peptide.self, Dose.self, Vendor.self, Price.self], inMemory: true)
}
