import SwiftUI

struct OnboardingView: View {
  @Binding var isPresented: Bool

  var body: some View {
    VStack(spacing: 0) {
      Spacer()

      PeptideArtwork(slug: "bpc-157", size: 88, cornerRadius: 22)
        .padding(.bottom, 24)

      Text("Compare smarter")
        .font(.largeTitle)
        .fontWeight(.bold)
        .multilineTextAlignment(.center)

      Text("Research peptide prices across suppliers — sorted by effective $/mg, not sticker price.")
        .font(.body)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
        .padding(.top, 10)

      VStack(alignment: .leading, spacing: 16) {
        onboardingRow(
          icon: "scalemass.fill",
          title: "Compare by $/mg",
          detail: "5mg vs 10mg vials are normalized so you see the real best deal."
        )
        onboardingRow(
          icon: "chart.xyaxis.line",
          title: "Track price drops",
          detail: "Daily snapshots show trends and lowest-ever prices."
        )
        onboardingRow(
          icon: "bell.badge",
          title: "Set alerts",
          detail: "Get notified when a peptide hits your target $/mg."
        )
      }
      .padding(.horizontal, 28)
      .padding(.top, 32)

      Spacer()

      Text("For research purposes only. Not medical advice.")
        .font(.caption)
        .foregroundStyle(.tertiary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)

      Button {
        isPresented = false
      } label: {
        Text("Get started")
          .font(.headline)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 16)
      }
      .buttonStyle(.borderedProminent)
      .tint(AppTheme.accent)
      .padding(.horizontal, 24)
      .padding(.top, 16)
      .padding(.bottom, 32)
    }
    .background(AppTheme.pageBackground)
  }

  private func onboardingRow(icon: String, title: String, detail: String) -> some View {
    HStack(alignment: .top, spacing: 14) {
      Image(systemName: icon)
        .font(.title3)
        .foregroundStyle(AppTheme.accent)
        .frame(width: 32)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.subheadline)
          .fontWeight(.semibold)
        Text(detail)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  OnboardingView(isPresented: .constant(true))
}
