import SwiftUI

struct SettingsScreenView: View {
    @Bindable var model: SettingsScreen

    var body: some View {
        Form {
            Section {
                Toggle("Vibrate", isOn: $model.vibratesWhenPaused)

                Toggle(isOn: $model.announcesWithVoiceOver) {
                    Text("Announce with VoiceOver")
                    Text("Only when VoiceOver is on")
                }
            } header: {
                Text("When captions pause")
            } footer: {
                Text("The screen always shows when captions pause.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { model.viewAppeared() }
        .onDisappear { model.viewDisappeared() }
    }
}

#Preview {
    NavigationStack {
        SettingsScreenView(model: SettingsScreen())
    }
}
