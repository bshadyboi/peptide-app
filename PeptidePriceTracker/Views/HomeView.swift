import SwiftUI
import SwiftData

struct HomeView: View {
  @Environment(\.modelContext) private var modelContext
  @EnvironmentObject private var syncService: DataSyncService
  @Query(sort: \Peptide.name) private var allPeptides: [Peptide]

  @State private var searchText = ""
  @State private var selectedTab: PeptideCategory = .single
  @State private var displayMode: PriceDisplayMode = .perMg
  @State private var sortOption: PeptideSortOption = .popularity
  @State private var selectedTopic: PeptideTopic = .all

  private var filteredPeptides: [Peptide] {
    let base = allPeptides
      .filter { $0.category == selectedTab }
      .filter { !PeptideCatalog.hiddenFromBrowseSlugs.contains($0.slug) }
      .filter { peptide in
        selectedTopic == .all || PeptideCatalog.topic(for: peptide.slug) == selectedTopic
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
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .principal) {
          VStack(spacing: 0) {
            Text("Peptide Prices")
              .font(.headline)
            Text("Compare by $/mg")
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
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
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        heroHeader

        if let error = syncService.lastError {
          Text(error)
            .font(.caption)
            .foregroundStyle(.red)
            .padding(.horizontal)
        }

        if searchText.isEmpty, !trendingPeptides.isEmpty {
          popularSection
        }

        controlsBar

        if syncService.isSyncing, filteredPeptides.isEmpty {
          ProgressView("Loading peptides…")
            .frame(maxWidth: .infinity)
            .padding(.vertical, 48)
        } else if filteredPeptides.isEmpty {
          emptyState
            .padding(.top, 24)
        } else {
          LazyVStack(spacing: 16) {
            ForEach(filteredPeptides, id: \.id) { peptide in
              PeptideCompareCard(peptide: peptide, displayMode: displayMode)
            }
          }
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 24)
    }
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

  private var heroHeader: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text("Find the Best Peptide Prices")
        .font(.title2)
        .fontWeight(.bold)
      Text("Compare across suppliers — sorted by effective $/mg, not sticker price.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
    .padding(.top, 8)
  }

  private var popularSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Popular")
        .font(.caption)
        .fontWeight(.semibold)
        .foregroundStyle(.secondary)
        .textCase(.uppercase)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(trendingPeptides, id: \.id) { peptide in
            NavigationLink {
              PeptideDetailView(peptide: peptide)
            } label: {
              Text(peptide.name)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(AppTheme.accentSoft)
                .foregroundStyle(AppTheme.accent)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }
    }
  }

  private var controlsBar: some View {
    VStack(spacing: 12) {
      Picker("Category", selection: $selectedTab) {
        Text("Singles").tag(PeptideCategory.single)
        Text("Blends").tag(PeptideCategory.blend)
      }
      .pickerStyle(.segmented)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(PeptideTopic.allCases) { topic in
            Button {
              selectedTopic = topic
            } label: {
              Text(topic.rawValue)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedTopic == topic ? AppTheme.accent : Color(.tertiarySystemFill))
                .foregroundStyle(selectedTopic == topic ? Color.white : Color.primary)
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
      }

      HStack {
        Text("\(filteredPeptides.count) result\(filteredPeptides.count == 1 ? "" : "s")")
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Spacer()

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
        }

        Picker("Show", selection: $displayMode) {
          ForEach(PriceDisplayMode.allCases, id: \.self) { mode in
            Text(mode.rawValue).tag(mode)
          }
        }
        .pickerStyle(.segmented)
        .frame(maxWidth: 140)
      }
    }
  }

  private var emptyState: some View {
    Group {
      if !searchText.isEmpty {
        ContentUnavailableView.search(text: searchText)
      } else if let error = syncService.lastError {
        ContentUnavailableView {
          Label("Sync Failed", systemImage: "exclamationmark.triangle")
        } description: {
          Text(error)
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
