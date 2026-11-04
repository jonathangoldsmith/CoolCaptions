import SwiftUI

struct PausedStatusView: View {
    let start: Date

    var body: some View {
        let title = Label("Captions paused", systemImage: "wifi.slash")
        let timer = Text(start, style: .timer).monospacedDigit()

        VStack(alignment: .leading) {
            // Side by side when it fits. Otherwise the timer goes under the title, so the title never breaks mid-word.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline) {
                    title
                    Spacer()
                    timer
                }

                // ViewThatFits offers this fallback one line of height, so let it grow to wrap the title.
                VStack(alignment: .leading) {
                    title
                    timer
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .font(.headline)

            Text("No connection · reconnecting automatically", comment: "Paused status subtitle, under \"Captions paused\".")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: Design.cardCornerRadius))
        .padding(.horizontal)
        // The pause announcement already says this. The timer would be read as digits, so leave it out.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(CaptioningScreen.pausedMessage)
        .accessibilityIdentifier("pausedStatus")
    }
}

#Preview {
    PausedStatusView(start: .now.addingTimeInterval(-12))
}

#Preview("Largest text") {
    PausedStatusView(start: .now.addingTimeInterval(-12))
        .dynamicTypeSize(.accessibility5)
}
