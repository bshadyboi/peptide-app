import SwiftUI

// MARK: - Background

struct DarkAuroraBackground: View {
  var body: some View {
    ZStack {
      AppTheme.darkBackground.ignoresSafeArea()

      RadialGradient(
        colors: [AppTheme.neonPurple.opacity(0.35), .clear],
        center: .init(x: 0.85, y: 0.08),
        startRadius: 0,
        endRadius: 280
      )
      .ignoresSafeArea()

      RadialGradient(
        colors: [AppTheme.neonCyan.opacity(0.22), .clear],
        center: .init(x: 0.15, y: 0.22),
        startRadius: 0,
        endRadius: 220
      )
      .ignoresSafeArea()

      LinearGradient(
        colors: [.clear, AppTheme.darkBackground.opacity(0.92)],
        startPoint: .top,
        endPoint: .bottom
      )
      .ignoresSafeArea()
    }
  }
}

// MARK: - Peptide monogram badge (replaces vial photos — names always readable)

struct PeptideMonogramBadge: View {
  let name: String
  let slug: String
  var size: CGFloat = 48

  private var topic: PeptideTopic {
    PeptideCatalog.topic(for: slug)
  }

  private var lines: [String] {
    PeptideMonogram.lines(for: name, slug: slug)
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
        .fill(
          LinearGradient(
            colors: topic.gradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      Image(systemName: PeptideVisuals.icon(for: slug))
        .font(.system(size: size * 0.52, weight: .light))
        .foregroundStyle(.white.opacity(0.14))

      VStack(spacing: lines.count > 1 ? -1 : 0) {
        ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
          Text(line)
            .font(.system(size: fontSize, weight: .heavy))
            .foregroundStyle(.white)
            .tracking(-0.3)
            .lineLimit(1)
            .minimumScaleFactor(0.55)
        }
      }
      .padding(.horizontal, size * 0.1)
    }
    .frame(width: size, height: size)
    .overlay {
      RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
        .strokeBorder(.white.opacity(0.22), lineWidth: 1)
    }
    .shadow(color: topic.accent.opacity(0.4), radius: size * 0.12, y: size * 0.06)
  }

  private var fontSize: CGFloat {
    let longest = lines.map(\.count).max() ?? 3
    let base = size * (lines.count > 1 ? 0.19 : 0.22)
    return base * (longest >= 5 ? 0.82 : 1)
  }
}

enum PeptideMonogram {
  private static let presets: [String: [String]] = [
    "bpc-157": ["BPC", "157"],
    "tb-500": ["TB", "500"],
    "semaglutide": ["SEMA"],
    "tirzepatide": ["TIRZ"],
    "retatrutide": ["RETA"],
    "survodutide": ["SURVO"],
    "cagrilintide": ["CAGR"],
    "ipamorelin": ["IPA"],
    "tesamorelin": ["TESA"],
    "sermorelin": ["SERM"],
    "ghrp-6": ["GHRP", "6"],
    "ghrp-2": ["GHRP", "2"],
    "cjc-1295-dac": ["CJC", "DAC"],
    "cjc-1295-no-dac": ["CJC"],
    "hexarelin": ["HEXA"],
    "ghk-cu": ["GHK"],
    "melanotan-ii": ["MT", "2"],
    "melanotan-i": ["MT", "1"],
    "pt-141": ["PT", "141"],
    "semax": ["SEMAX"],
    "selank": ["SELNK"],
    "dsip": ["DSIP"],
    "epitalon": ["EPIT"],
    "nad-plus": ["NAD+"],
    "mots-c": ["MOTS"],
    "foxo4-dri": ["FOXO4"],
    "igf-1-lr3": ["IGF", "LR3"],
    "peg-mgf": ["PEG", "MGF"],
    "ta-1": ["TA", "1"],
    "thymalin": ["THYM"],
    "kpv": ["KPV"],
    "ll-37": ["LL", "37"],
    "aod-9604": ["AOD", "96"],
    "adamax": ["ADMX"],
    "dihexa": ["DHX"],
    "snap-8": ["SNAP", "8"],
    "vip": ["VIP"],
    "oxytocin": ["OXY"],
    "kisspeptin": ["KISS"],
    "hgh-frag-176-191": ["HGH"],
    "ara-290": ["ARA", "290"],
    "glutathione": ["GSH"],
    "ss-31": ["SS", "31"],
    "5-amino-1mq": ["1MQ"],
    "bpc-tb-blend": ["BPC", "TB"],
    "glow-blend": ["GLOW"],
    "klow-blend": ["KLOW"],
    "ghk-kpv-blend": ["GHK", "KPV"],
    "cjc-ipa-blend": ["CJC", "IPA"],
    "tes-ipa-blend": ["TES", "IPA"],
    "ghrp-ipa-blend": ["GHRP", "IPA"],
  ]

  static func lines(for name: String, slug: String) -> [String] {
    if let preset = presets[slug] {
      return preset.map { $0.uppercased() }
    }
    return autoLines(name: name, slug: slug)
  }

  private static func autoLines(name: String, slug: String) -> [String] {
    let fromSlug = slug
      .replacingOccurrences(of: "-blend", with: "")
      .split(separator: "-")
      .map { String($0).uppercased() }
    if fromSlug.count >= 2 {
      return [fromSlug[0], fromSlug[1...].joined(separator: "-")]
    }
    let upper = name.trimmingCharacters(in: .whitespaces).uppercased()
    if upper.count <= 4 { return [upper] }
    if upper.count <= 7 {
      let mid = (upper.count + 1) / 2
      let idx = upper.index(upper.startIndex, offsetBy: mid)
      return [String(upper[..<idx]), String(upper[idx...])]
    }
    return [String(upper.prefix(4)), String(upper.dropFirst(4).prefix(4))]
  }
}

// MARK: - Chips

struct DarkTopicChip: View {
  let topic: PeptideTopic
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 6) {
        Image(systemName: topic.icon)
          .font(.caption2.weight(.bold))
        Text(topic.rawValue)
          .font(.caption.weight(.semibold))
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 9)
      .background {
        if isSelected {
          Capsule()
            .fill(
              LinearGradient(
                colors: [AppTheme.neonCyan.opacity(0.35), AppTheme.neonPurple.opacity(0.35)],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .overlay {
              Capsule()
                .strokeBorder(
                  LinearGradient(
                    colors: [AppTheme.neonCyan, AppTheme.neonPurple],
                    startPoint: .leading,
                    endPoint: .trailing
                  ),
                  lineWidth: 1.5
                )
            }
        } else {
          Capsule()
            .fill(AppTheme.darkCard.opacity(0.85))
            .overlay {
              Capsule().strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            }
        }
      }
      .foregroundStyle(isSelected ? .white : Color.white.opacity(0.72))
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Hero card

struct BestDealHeroCard: View {
  let peptide: Peptide
  let badge: String
  var displayMode: PriceDisplayMode = .perMg

  private var topic: PeptideTopic {
    PeptideCatalog.topic(for: peptide.slug)
  }

  private var best: Price? {
    guard let dose = peptide.defaultDose else { return nil }
    return Price.sortedForCompare(dose.prices).first(where: \.inStock)
  }

  var body: some View {
    NavigationLink {
      PeptideDetailView(peptide: peptide)
    } label: {
      HStack(alignment: .center, spacing: 12) {
        VStack(alignment: .leading, spacing: 10) {
          HStack(spacing: 5) {
            Image(systemName: "star.fill")
              .font(.caption2)
              .foregroundStyle(AppTheme.neonCyan)
            Text(badge.uppercased())
              .font(.caption2.weight(.heavy))
              .tracking(0.6)
              .foregroundStyle(AppTheme.neonCyan)
          }

          Text(peptide.name)
            .font(.title2.weight(.bold))
            .foregroundStyle(.white)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          if let best {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
              Text("Price starting at")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.65))
              Text(
                displayMode == .perMg
                  ? (best.pricePerMg.map { CurrencyFormatter.formatPerMg($0) } ?? "—")
                  : CurrencyFormatter.format(best.effectivePrice)
              )
              .font(.title3.weight(.bold))
              .foregroundStyle(AppTheme.neonCyan)
              .monospacedDigit()
            }

            if let dose = peptide.defaultDose {
              Text("\(dose.displayName) · \(vendorCount) vendors")
                .font(.caption)
                .foregroundStyle(Color.white.opacity(0.55))
            }
          }

          HStack(spacing: 4) {
            Text("View Deals")
              .font(.subheadline.weight(.semibold))
            Image(systemName: "arrow.right")
              .font(.caption.weight(.bold))
          }
          .foregroundStyle(.white)
          .padding(.top, 2)
        }

        Spacer(minLength: 0)

        ZStack {
          Circle()
            .fill(
              RadialGradient(
                colors: [topic.accent.opacity(0.45), .clear],
                center: .center,
                startRadius: 0,
                endRadius: 52
              )
            )
            .frame(width: 100, height: 100)

          PeptideMonogramBadge(
            name: peptide.name,
            slug: peptide.slug,
            size: 76
          )
        }
        .frame(width: 96)
      }
      .padding(18)
      .background {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
          .fill(AppTheme.darkCard.opacity(0.92))
          .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
              .strokeBorder(
                LinearGradient(
                  colors: [
                    AppTheme.neonCyan.opacity(0.7),
                    AppTheme.neonPurple.opacity(0.55),
                    AppTheme.neonCyan.opacity(0.25),
                  ],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                ),
                lineWidth: 1.5
              )
          }
          .shadow(color: AppTheme.neonPurple.opacity(0.22), radius: 16, y: 8)
      }
    }
    .buttonStyle(.plain)
  }

  private var vendorCount: Int {
    guard let dose = peptide.defaultDose else { return 0 }
    return dose.prices.filter(\.inStock).count
  }
}

// MARK: - List row

struct DarkPeptideListRow: View {
  let peptide: Peptide
  let displayMode: PriceDisplayMode

  private var topic: PeptideTopic {
    PeptideCatalog.topic(for: peptide.slug)
  }

  private var best: Price? {
    guard let dose = peptide.defaultDose else { return nil }
    return Price.sortedForCompare(dose.prices).first(where: \.inStock)
  }

  private var vendorCount: Int {
    guard let dose = peptide.defaultDose else { return 0 }
    return dose.prices.filter(\.inStock).count
  }

  var body: some View {
    HStack(spacing: 12) {
      PeptideMonogramBadge(name: peptide.name, slug: peptide.slug, size: 50)

      VStack(alignment: .leading, spacing: 5) {
        Text(peptide.name)
          .font(.body.weight(.semibold))
          .foregroundStyle(.white)
          .lineLimit(1)

        HStack(spacing: 6) {
          if peptide.category == .blend {
            DarkCategoryPill(label: "Blend", color: AppTheme.neonPurple)
          } else if topic != .all {
            DarkCategoryPill(label: topic.rawValue, color: topic.accent)
          }

          if vendorCount > 0 {
            DarkCategoryPill(
              label: "\(vendorCount) deal\(vendorCount == 1 ? "" : "s")",
              color: Color.white.opacity(0.55),
              filled: false
            )
          }
          if PeptideDeals.hasActiveDeal(peptide) {
            DealBadge()
          }
        }

        if let dose = peptide.defaultDose {
          Text(dose.displayName)
            .font(.caption)
            .foregroundStyle(Color.white.opacity(0.45))
        }
      }

      Spacer(minLength: 0)

      VStack(alignment: .trailing, spacing: 4) {
        if let best {
          Text("from")
            .font(.caption2)
            .foregroundStyle(Color.white.opacity(0.45))
          Text(
            displayMode == .perMg
              ? (best.pricePerMg.map { CurrencyFormatter.formatPerMg($0) } ?? "—")
              : CurrencyFormatter.format(best.effectivePrice)
          )
          .font(.subheadline.weight(.bold))
          .foregroundStyle(.white)
          .monospacedDigit()
        }

        Image(systemName: "chevron.right")
          .font(.caption2.weight(.semibold))
          .foregroundStyle(Color.white.opacity(0.35))
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background {
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(AppTheme.darkCard.opacity(0.75))
        .overlay {
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        }
    }
  }
}

struct DarkCategoryPill: View {
  let label: String
  let color: Color
  var filled: Bool = true

  var body: some View {
    Text(label)
      .font(.caption2.weight(.semibold))
      .foregroundStyle(filled ? color : color.opacity(0.9))
      .padding(.horizontal, 8)
      .padding(.vertical, 3)
      .background {
        Capsule()
          .fill(filled ? color.opacity(0.18) : Color.white.opacity(0.06))
      }
  }
}

struct DarkSectionHeader: View {
  let title: String
  var trailing: String?

  var body: some View {
    HStack {
      Text(title)
        .font(.headline.weight(.bold))
        .foregroundStyle(.white)
      Spacer()
      if let trailing {
        Text(trailing)
          .font(.caption.weight(.medium))
          .foregroundStyle(AppTheme.neonCyan)
      }
    }
  }
}
