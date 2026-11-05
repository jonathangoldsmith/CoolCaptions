import SwiftUI

struct TranscriptView: View {
    let model: CaptioningScreen

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                ForEach(model.items) { item in
                    // One VStack per row, so SwiftUI can identify rows from their ids alone.
                    VStack(alignment: .leading) {
                        Divider()

                        switch item {
                            case .caption(let caption):
                                Text(caption.body).padding()

                            case .gap(let gap):
                                // `items` only holds finished gaps, which always have a duration.
                                let missed = gap.duration ?? .zero
                                GapMarkerView(text: model.markerText(missed: missed), label: model.markerLabel(missed: missed))
                        }
                    }
                }
            }
        }
        .defaultScrollAnchor(.bottom)
        .defaultScrollAnchor(.bottom, for: .sizeChanges)
    }
}
