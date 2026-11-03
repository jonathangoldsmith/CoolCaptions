import SwiftUI

struct CaptioningScreenView: View {
    let model: CaptioningScreen
    @Environment(\.dynamicTypeSize) var dynamicTypeSize

    // MARK: -

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(model.items) { item in
                    switch item {
                        case .caption(let caption):
                            Divider()
                            Text(caption.body).padding()

                        case .gap(let gap):
                            // An open gap shows as the paused status instead.
                            if let missed = gap.duration {
                                Divider()
                                gapMarker(missed: missed)
                            }
                    }
                }
            }
        }
        .defaultScrollAnchor(.bottom)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
        .navigationTitle("Cool Captions")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 12) {
                if let pausedSince = model.pausedSince {
                    pausedStatus(since: pausedSince)
                }

                Button(model.toggleButtonTitle) {
                    model.toggleButtonWasPressed()
                }.buttonStyle(.glass)
            }
        }
        .sensoryFeedback(.warning, trigger: model.hapticTrigger)
        .onChange(of: model.connectionStatus) { model.connectionStatusChanged() }
        .onAppear { model.viewAppeared() }
        .onDisappear { model.viewDisappeared() }
    }

    func gapMarker(missed: Duration) -> some View {
        Label(model.markerText(missed: missed), systemImage: "exclamationmark.triangle")
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.markerLabel(missed: missed))
            .accessibilityIdentifier("gapMarker")
    }

    func pausedStatus(since start: Date) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // At accessibility text sizes the timer goes under the title, or the title breaks mid-word.
            if dynamicTypeSize.isAccessibilitySize {
                Label("Captions paused", systemImage: "wifi.slash").font(.headline)
                Text(start, style: .timer).font(.headline).monospacedDigit()
            } else {
                HStack(alignment: .firstTextBaseline) {
                    Label("Captions paused", systemImage: "wifi.slash")
                    Spacer()
                    Text(start, style: .timer).monospacedDigit()
                }
                .font(.headline)
            }

            Text("No connection · reconnecting automatically")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
        // The pause announcement already says this. The timer would be read as digits, so leave it out.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Captions paused. No connection. Reconnecting automatically.")
        .accessibilityIdentifier("pausedStatus")
    }
}
