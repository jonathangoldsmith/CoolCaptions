@MainActor final class AnnouncementSpy {
    private(set) var messages: [String] = []

    func announce(_ message: String) {
        messages.append(message)
    }
}
