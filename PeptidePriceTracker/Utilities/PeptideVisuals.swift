import SwiftUI

enum PeptideVisuals {
  static func icon(for slug: String) -> String {
    switch slug {
    case "bpc-157", "kpv":
      return "cross.case.fill"
    case "tb-500":
      return "figure.run"
    case "bpc-tb-blend", "glow-blend", "klow-blend":
      return "leaf.fill"
    case "semaglutide", "tirzepatide", "retatrutide", "cagrilintide":
      return "scalemass.fill"
    case "ipamorelin", "tesamorelin", "sermorelin", "ghrp-6", "ghrp-2", "cjc-ipa-blend":
      return "arrow.up.heart.fill"
    case "cjc-1295-dac", "hexarelin":
      return "bolt.heart.fill"
    case "ghk-cu", "melanotan-ii", "melanotan-i", "pt-141":
      return "sparkles"
    case "semax", "selank", "dsip":
      return "brain.head.profile"
    case "epitalon", "nad-plus", "mots-c", "ss-31", "5-amino-1mq", "glutathione":
      return "hourglass"
    case "aod-9604", "ll-37":
      return "flame.fill"
    case "ta-1", "thymalin":
      return "shield.lefthalf.filled"
    case "igf-1-lr3", "peg-mgf":
      return "figure.strengthtraining.traditional"
    case "foxo4-dri":
      return "hourglass"
    case "dihexa", "adamax":
      return "brain.head.profile"
    case "snap-8":
      return "sparkles"
    case "vip", "oxytocin", "kisspeptin":
      return "heart.fill"
    case "hgh-frag-176-191":
      return "flame.fill"
    case "survodutide":
      return "scalemass.fill"
    case "ghk-kpv-blend":
      return "leaf.fill"
    case "tes-ipa-blend", "ghrp-ipa-blend":
      return "arrow.up.heart.fill"
    case "ara-290":
      return "cross.case.fill"
    default:
      return PeptideCatalog.topic(for: slug).icon
    }
  }
}

extension PeptideTopic {
  var icon: String {
    switch self {
    case .all: return "square.grid.2x2.fill"
    case .healing: return "cross.case.fill"
    case .growth: return "arrow.up.heart.fill"
    case .glp: return "scalemass.fill"
    case .cosmetic: return "sparkles"
    case .cognitive: return "brain.head.profile"
    case .longevity: return "hourglass"
    }
  }

  var gradient: [Color] {
    switch self {
    case .all:
      return [AppTheme.accent, Color(red: 0.12, green: 0.38, blue: 0.72)]
    case .healing:
      return [Color(red: 0.12, green: 0.62, blue: 0.52), Color(red: 0.08, green: 0.45, blue: 0.68)]
    case .growth:
      return [Color(red: 0.22, green: 0.42, blue: 0.88), Color(red: 0.35, green: 0.28, blue: 0.82)]
    case .glp:
      return [Color(red: 0.52, green: 0.28, blue: 0.82), Color(red: 0.68, green: 0.22, blue: 0.58)]
    case .cosmetic:
      return [Color(red: 0.88, green: 0.38, blue: 0.58), Color(red: 0.72, green: 0.28, blue: 0.68)]
    case .cognitive:
      return [Color(red: 0.18, green: 0.52, blue: 0.82), Color(red: 0.12, green: 0.38, blue: 0.72)]
    case .longevity:
      return [Color(red: 0.78, green: 0.52, blue: 0.18), Color(red: 0.58, green: 0.36, blue: 0.22)]
    }
  }

  var accent: Color { gradient[0] }
}

struct PeptideArtwork: View {
  let slug: String
  var size: CGFloat = 44
  var cornerRadius: CGFloat = 12

  private var topic: PeptideTopic {
    PeptideCatalog.topic(for: slug)
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        .fill(
          LinearGradient(
            colors: topic.gradient,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )

      Circle()
        .fill(.white.opacity(0.14))
        .frame(width: size * 0.72, height: size * 0.72)
        .offset(x: size * 0.22, y: -size * 0.18)

      Circle()
        .fill(.white.opacity(0.08))
        .frame(width: size * 0.38, height: size * 0.38)
        .offset(x: -size * 0.24, y: size * 0.2)

      Image(systemName: PeptideVisuals.icon(for: slug))
        .font(.system(size: size * 0.38, weight: .semibold))
        .foregroundStyle(.white)
        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
    }
    .frame(width: size, height: size)
    .shadow(color: topic.accent.opacity(0.28), radius: 6, y: 3)
  }
}

struct TopicFilterChip: View {
  let topic: PeptideTopic
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 5) {
        Image(systemName: topic.icon)
          .font(.caption2.weight(.bold))
        Text(topic.rawValue)
          .font(.caption)
          .fontWeight(.medium)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 7)
      .background {
        if isSelected {
          Capsule().fill(
            LinearGradient(colors: topic.gradient, startPoint: .leading, endPoint: .trailing)
          )
        } else {
          Capsule().fill(Color(.tertiarySystemFill))
        }
      }
      .foregroundStyle(isSelected ? Color.white : Color.primary)
    }
    .buttonStyle(.plain)
  }
}

struct TopicExploreTile: View {
  let topic: PeptideTopic
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 10) {
        Image(systemName: topic.icon)
          .font(.title3.weight(.semibold))
          .foregroundStyle(.white)

        Text(topic.rawValue)
          .font(.caption)
          .fontWeight(.bold)
          .foregroundStyle(.white)
          .lineLimit(1)
      }
      .padding(12)
      .frame(width: 92, height: 88, alignment: .leading)
      .background(
        LinearGradient(colors: topic.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
      )
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
      .overlay {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
          .strokeBorder(isSelected ? Color.white.opacity(0.9) : .clear, lineWidth: 2)
      }
      .overlay(alignment: .topTrailing) {
        Circle()
          .fill(.white.opacity(0.12))
          .frame(width: 36, height: 36)
          .offset(x: 10, y: -10)
      }
      .scaleEffect(isSelected ? 1.03 : 1)
      .animation(.spring(response: 0.28), value: isSelected)
    }
    .buttonStyle(.plain)
  }
}

struct HomeHeroBanner: View {
  let vendorCount: Int
  let peptideCount: Int

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      Image("HeroHome")
        .resizable()
        .scaledToFill()
        .frame(height: 148)
        .clipped()

      LinearGradient(
        colors: [.black.opacity(0.05), .black.opacity(0.55)],
        startPoint: .top,
        endPoint: .bottom
      )

      HStack(alignment: .bottom) {
        VStack(alignment: .leading, spacing: 4) {
          Text("Research peptide prices")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white.opacity(0.85))
            .textCase(.uppercase)

          Text("Find the best $/mg")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
        }

        Spacer()

        VStack(alignment: .trailing, spacing: 2) {
          Text("\(vendorCount)")
            .font(.title3)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .monospacedDigit()
          Text("suppliers")
            .font(.caption2)
            .foregroundStyle(.white.opacity(0.85))
        }
      }
      .padding(16)
    }
    .frame(height: 148)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: AppTheme.accent.opacity(0.22), radius: 12, y: 6)
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Compare \(peptideCount) peptides across \(vendorCount) suppliers")
  }
}

struct PeptideHeroBanner: View {
  let peptide: Peptide

  private var topic: PeptideTopic {
    PeptideCatalog.topic(for: peptide.slug)
  }

  var body: some View {
    ZStack(alignment: .bottomLeading) {
      LinearGradient(
        colors: topic.gradient,
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )

      Image(systemName: PeptideVisuals.icon(for: peptide.slug))
        .font(.system(size: 88, weight: .light))
        .foregroundStyle(.white.opacity(0.16))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(12)

      Circle()
        .fill(.white.opacity(0.1))
        .frame(width: 120, height: 120)
        .offset(x: -30, y: -20)

      HStack(alignment: .center, spacing: 14) {
        PeptideArtwork(slug: peptide.slug, size: 56, cornerRadius: 16)

        VStack(alignment: .leading, spacing: 4) {
          if peptide.category == .blend {
            Text("Blend")
              .font(.caption2.weight(.bold))
              .foregroundStyle(.white.opacity(0.9))
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(.white.opacity(0.18))
              .clipShape(Capsule())
          } else if topic != .all {
            Text(topic.rawValue)
              .font(.caption2.weight(.bold))
              .foregroundStyle(.white.opacity(0.9))
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(.white.opacity(0.18))
              .clipShape(Capsule())
          }

          Text(peptide.name)
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .lineLimit(2)
        }

        Spacer()
      }
      .padding(16)
    }
    .frame(height: 132)
    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    .shadow(color: topic.accent.opacity(0.25), radius: 10, y: 5)
  }
}
