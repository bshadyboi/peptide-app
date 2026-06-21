import SwiftUI
import SwiftData

struct HomeView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @Query(sort: \Peptide.name) private var allPeptides: [Peptide]
  @Query(sort: \Vendor.name) private var allVendors: [Vendor]
  @Query private var allPrices: [Price]

  @State private var searchText = ""
  @State private var selectedTab: PeptideCategory = .single
  @State private var displayMode: PriceDisplayMode = .perMg
  @State private var sortOption: PeptideSortOption = .popularity
  @State private var selectedTopic: PeptideTopic = .all
  @State private var selectedVendorFilterID: UUID?
  @State private var dealsOnly = false
  @State private var showVendorsSheet = false
  @State private var highlight: HomeHighlight?
  @State private var featuredIndex = 0

  private var liveVendorCount: Int {
    VendorCatalog.liveVendors(from: allVendors, prices: allPrices).count
  }

  private var filteredPeptides: [Peptide] {
    var list = allPeptides.filter { $0.category == selectedTab }
    list = list.filter { !PeptideCatalog.hiddenFromBrowseSlugs.contains($0.slug) }
    if selectedTopic != .all {
      list = list.filter { PeptideCatalog.topic(for: $0.slug) == selectedTopic }
    }
    if let vendorID = selectedVendorFilterID {
      list = list.filter { VendorCatalog.peptideHasInStockPrice(from: vendorID, peptide: $0) }
    }
    if dealsOnly {
      list = list.filter { PeptideDeals.hasActiveDeal($0) }
    }
    if !searchText.isEmpty {
      let q = searchText.lowercased()
      list = list.filter {
        $0.name.lowercased().contains(q) || $0.slug.lowercased().contains(q)
          || $0.aliases.contains { $0.lowercased().contains(q) }
      }
    }
    switch sortOption {
    case .name:
      return list.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    case .popularity:
      return list.sorted { PeptideCatalog.popularityRank(for: $0.slug) < PeptideCatalog.popularityRank(for: $1.slug) }
    case .price:
      return list.sorted { ($0.bestPricePerMg ?? Decimal.sortSentinel) < ($1.bestPricePerMg ?? Decimal.sortSentinel) }
    }
  }

  private var featuredPeptides: [Peptide] {
    var slugs = PeptideCatalog.popularSlugs
    if let highlight {
      slugs.removeAll { $0 == highlight.peptide.slug }
      slugs.insert(highlight.peptide.slug, at: 0)
    }
    return slugs.prefix(5).compactMap { slug in
      allPeptides.first { $0.slug == slug && $0.bestPricePerMg != nil }
    }
  }

  var body: some View {
    NavigationStack {
      ZStack {
        DarkAuroraBackground()

        Group {
          if !SupabaseConfig.isConfigured {
            configurationPrompt
          } else {
            browseContent
          }
        }
      }
      .navigationTitle("Compare")
      .navigationBarTitleDisplayMode(.large)
      .toolbarBackground(.hidden, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Menu {
            Picker("Sort", selection: $sortOption) {
              ForEach(PeptideSortOption.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            Picker("Show", selection: $displayMode) {
              ForEach(PriceDisplayMode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            Toggle("Deals only", isOn: $dealsOnly)
            Button { showVendorsSheet = true } label: {
              Label("Filter by supplier", systemImage: "building.2")
            }
          } label: {
            Image(systemName: "slider.horizontal.3")
              .foregroundStyle(AppTheme.neonCyan)
          }
        }
      }
      .searchable(text: $searchText, prompt: "Search peptides")
      .preferredColorScheme(.dark)
      .task { await refresh() }
      .refreshable { await refresh() }
      .sheet(isPresented: $showVendorsSheet) {
        VendorsListSheet(selectedVendorFilterID: $selectedVendorFilterID)
      }
    }
  }

  private var browseContent: some View {
    ScrollView {
      LazyVStack(alignment: .leading, spacing: 22) {
        headerSubtitle

        if searchText.isEmpty, !featuredPeptides.isEmpty {
          featuredCarousel
        }

        topicFilters

        categoryPicker

        if let error = syncService.lastError {
          Text(error)
            .font(.caption)
            .foregroundStyle(.red.opacity(0.9))
            .padding(.horizontal, 4)
        }

        DarkSectionHeader(
          title: searchText.isEmpty ? "Popular Peptides" : "Results",
          trailing: "\(filteredPeptides.count) · \(liveVendorCount) suppliers"
        )

        if syncService.isSyncing, filteredPeptides.isEmpty {
          ProgressView("Loading…")
            .tint(AppTheme.neonCyan)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else if filteredPeptides.isEmpty {
          emptyState
        } else {
          LazyVStack(spacing: 10) {
            ForEach(filteredPeptides, id: \.id) { peptide in
              NavigationLink {
                PeptideDetailView(peptide: peptide)
              } label: {
                DarkPeptideListRow(peptide: peptide, displayMode: displayMode)
              }
              .buttonStyle(.plain)
            }
          }
        }
      }
      .padding(.horizontal, 16)
      .padding(.bottom, 24)
    }
  }

  private var headerSubtitle: some View {
    Text("Find the best peptide prices")
      .font(.subheadline)
      .foregroundStyle(Color.white.opacity(0.55))
      .padding(.top, -8)
  }

  private var featuredCarousel: some View {
    TabView(selection: $featuredIndex) {
      ForEach(Array(featuredPeptides.enumerated()), id: \.element.id) { index, peptide in
        BestDealHeroCard(
          peptide: peptide,
          badge: carouselBadge(for: peptide, index: index),
          displayMode: displayMode
        )
        .tag(index)
      }
    }
    .tabViewStyle(.page(indexDisplayMode: .always))
    .frame(height: 230)
  }

  private func carouselBadge(for peptide: Peptide, index: Int) -> String {
    if index == 0, let highlight, highlight.peptide.id == peptide.id {
      return highlight.title
    }
    return "Best deal"
  }

  private var topicFilters: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(PeptideTopic.allCases) { topic in
          DarkTopicChip(topic: topic, isSelected: selectedTopic == topic) {
            selectedTopic = topic
          }
        }
      }
      .padding(.vertical, 2)
    }
  }

  private var categoryPicker: some View {
    HStack(spacing: 10) {
      ForEach([PeptideCategory.single, .blend], id: \.self) { category in
        Button {
          selectedTab = category
        } label: {
          Text(category == .single ? "Singles" : "Blends")
            .font(.caption.weight(.semibold))
            .foregroundStyle(selectedTab == category ? .white : Color.white.opacity(0.55))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background {
              Capsule()
                .fill(selectedTab == category ? AppTheme.darkCard : Color.white.opacity(0.06))
                .overlay {
                  if selectedTab == category {
                    Capsule().strokeBorder(AppTheme.neonCyan.opacity(0.5), lineWidth: 1)
                  }
                }
            }
        }
        .buttonStyle(.plain)
      }

      if selectedVendorFilterID != nil {
        Button {
          selectedVendorFilterID = nil
        } label: {
          Label("Clear supplier", systemImage: "xmark.circle.fill")
            .font(.caption)
            .foregroundStyle(AppTheme.neonCyan)
        }
      }

      Spacer()
    }
  }

  private func refresh() async {
    guard SupabaseConfig.isConfigured else { return }
    await syncService.syncCatalog(context: modelContext)
    highlight = HomeHighlight.load(from: allPeptides, context: modelContext)
  }

  private var configurationPrompt: some View {
    ContentUnavailableView {
      Label("Supabase Not Configured", systemImage: "key.slash")
    } description: {
      Text("Copy Secrets.xcconfig.example to Secrets.xcconfig and add your project URL and anon key.")
    }
  }

  private var emptyState: some View {
    Group {
      if !searchText.isEmpty {
        ContentUnavailableView.search(text: searchText)
      } else {
        ContentUnavailableView {
          Label("No Peptides", systemImage: "pills")
        } actions: {
          Button("Retry") { Task { await refresh() } }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 32)
  }
}

#Preview {
  HomeView()
    .environmentObject(DataSyncService(api: nil, authSession: AuthSession()))
    .modelContainer(for: [Peptide.self, Dose.self, Vendor.self, Price.self], inMemory: true)
}
