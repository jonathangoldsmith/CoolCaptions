import SwiftUI

struct GapMarkerView: View {
    let text: String
    let label: String

    var body: some View {
        Label(text, systemImage: "exclamationmark.triangle")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityIdentifier("gapMarker")
    }
}

#Preview {
    GapMarkerView(
        text: "Missed 1 min, 12 sec (no connection)",
        label: "Missed 1 minute, 12 seconds. No connection."
    )
}
