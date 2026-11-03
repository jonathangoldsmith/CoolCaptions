import Foundation

@Observable class Captioner {
    let analytics: Analytics
    let connection: Connection
    let wait: (Duration) async throws -> Void

    /// `wait` stands in for the time between lines. Tests replace it so nothing arrives on its own.
    init(
        analytics: Analytics, connection: Connection,
        wait: @escaping (Duration) async throws -> Void = { try await Task.sleep(for: $0) }
    ) {
        self.analytics = analytics
        self.connection = connection
        self.wait = wait
    }

    // MARK: -

    var captions: [Caption] = []
    let conversation: Conversation = .mock

    var task: Task<Void, Never>?
    var isRunning: Bool { task != nil }

    // MARK: -

    func start() {
        guard task == nil else { return }
        analytics.track(.captioningStarted)
        task = Task { try? await run() }
    }

    func stop() {
        guard let task else { return }
        analytics.track(.captioningStopped)
        task.cancel()
        self.task = nil
    }

    // MARK: -

    /// Play the canned conversation as if real audio were being captioned,
    /// giving somewhat-realistic behavior depending on the connection status.
    ///
    private func run() async throws {
        for index in 0... {
            try Task.checkCancellation()
            try await wait(.seconds(.random(in: 1...6)))
            // A wait can finish just before Stop cancels it, so check again before acting.
            try Task.checkCancellation()

            let line = conversation.line(at: index)
            let caption = Caption(id: UUID(), date: Date(), body: line)

            switch connection.status {
                case .healthy:
                    captions.append(caption)
                    analytics.track(.captionWasReceived)

                case .degraded:
                    try await wait(.seconds(5))
                    try Task.checkCancellation()
                    captions.append(caption)
                    analytics.track(.captionWasReceived)

                case .disconnected:
                    analytics.track(.captionWasMissed)
            }
        }
    }
}
