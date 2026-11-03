import SwiftUI

struct CaptioningScreenView: View {
    let model: CaptioningScreen

    // MARK: -

    var body: some View {
        // A separate view, so `items` is only rebuilt when captions, gaps or flags change.
        TranscriptView(model: model)
            .navigationTitle("Cool Captions")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaBar(edge: .bottom) {
                VStack {
                    if let pausedSince = model.pausedSince {
                        PausedStatusView(start: pausedSince)
                    }

                    Button(model.toggleButtonTitle, action: model.toggleButtonWasPressed)
                        .buttonStyle(.glass)
                }
            }
            .sensoryFeedback(.warning, trigger: model.hapticTrigger)
            .onAppear { model.viewAppeared() }
            .onDisappear { model.viewDisappeared() }
    }
}
