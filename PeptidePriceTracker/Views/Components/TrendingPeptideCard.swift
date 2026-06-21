import SwiftUI

struct TrendingPeptideCard: View {
  let peptide: Peptide

  private var bestPerMg: Decimal? { peptide.bestPricePerMg }

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
        .font(.system(size: 56, weight: .light))
        .foregroundStyle(.white.opacity(0.18))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        .padding(8)

      Circle()
        .fill(.white.opacity(0.1))
        .frame(width: 64, height: 64)
        .offset(x: -20, y: -24)

      VStack(alignment: .leading, spacing: 8) {
        HStack(spacing: 6) {
          Image(systemName: PeptideVisuals.icon(for: peptide.slug))
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

          if topic != .all {
            Text(topic.rawValue)
              .font(.caption2)
              .fontWeight(.bold)
              .foregroundStyle(.white.opacity(0.9))
              .textCase(.uppercase)
          }
        }

        Text(peptide.name)
          .font(.subheadline)
          .fontWeight(.bold)
          .foregroundStyle(.white)
          .lineLimit(2)
          .multilineTextAlignment(.leading)

        if let best = bestPerMg {
          Text("from \(CurrencyFormatter.formatPerMg(best))")
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundStyle(.white.opacity(0.95))
            .monospacedDigit()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.black.opacity(0.18))
            .clipShape(Capsule())
        } else {
          Text("No prices yet")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.75))
        }
      }
      .padding(14)
    }
    .frame(width: 158, height: 118, alignment: .leading)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .shadow(color: topic.accent.opacity(0.3), radius: 8, y: 4)
  }
}
