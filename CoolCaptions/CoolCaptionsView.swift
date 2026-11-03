import SwiftUI

struct CoolCaptionsView: View {
    @Bindable var model: CoolCaptions
    @Environment(\.scenePhase) var scenePhase

    // MARK: -

    var body: some View {
        NavigationStack {
            CaptioningScreenView(model: model.captioningScreen)
                .toolbar {
                    debugButton
                    settingsButton
                }
        }
        .onChange(of: scenePhase) { model.scenePhaseChanged(to: $1) }
        .sheet(isPresented: $model.isDebugScreenVisible) { debugScreen }
        .sheet(isPresented: $model.isSettingsScreenVisible) { settingsScreen }
    }

    var debugButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button("Debug", systemImage: "ladybug") {
                model.debugButtonWasPressed()
            }
        }
    }

    var settingsButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if model.isSettingsButtonVisible {
                Button("Settings", systemImage: "gearshape") {
                    model.settingsButtonWasPressed()
                }
            }
        }
    }

    var debugScreen: some View {
        NavigationStack { DebugScreenView(model: model.debugScreen) }
            .presentationDetents([.medium])
    }

    var settingsScreen: some View {
        NavigationStack { SettingsScreenView(model: model.settingsScreen) }
            .presentationDetents([.medium])
    }
}
