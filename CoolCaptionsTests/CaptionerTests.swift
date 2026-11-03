import Testing
@testable import CoolCaptions

@MainActor struct CaptionerTests {
    let analytics = AnalyticsSpy()

    /// The wait ignores cancellation and returns normally, like a `Task.sleep` whose timer fired just before Stop.
    @Test func nothingHappensAfterStopWhenAWaitEndsLate() async {
        let (waitStarted, signal) = AsyncStream<Void>.makeStream()
        let captioner = Captioner(analytics: analytics, connection: Connection(analytics: analytics), wait: { _ in
            signal.yield()
            try? await Task.sleep(for: .seconds(3600))
        })

        captioner.start()
        for await _ in waitStarted { break }
        let task = captioner.task
        captioner.stop()
        await task?.value

        #expect(captioner.captions.isEmpty)
        #expect(analytics.events == [.captioningStarted, .captioningStopped])
    }
}
