//
// Copyright © 2020 mycujoo. All rights reserved.
//

import AVFoundation

public class VideoPlayer: NSObject {

    // MARK: - Public properties

    public private(set) var state: State = .idle
    public weak var delegate: PlayerDelegate?
    public private(set) var view = VideoPlayerView()

    public var event: Event? {
        didSet {
            guard let stream = event?.stream else { return }

            player.replaceCurrentItem(with: AVPlayerItem(url: stream.urls.first))
            view.drawPlayer(with: player)
        }
    }

    public private(set) var status: Status = .pause {
        didSet {
            switch status {
            case .play:
                player.play()
            case .pause:
                player.pause()
            }
            delegate?.playerDidUpdatePlaying(player: self)
        }
    }

    // MARK: - Private properties

    private let player = AVPlayer()
    private var timeObserver: Any?

    // MARK: - Methods

    public override init() {
        super.init()
        player.addObserver(self, forKeyPath: "currentItem.loadedTimeRanges", options: .new, context: nil)
        timeObserver = trackTime(with: player)
    }

    deinit {
        if let timeObserver = timeObserver { player.removeTimeObserver(timeObserver) }
        player.removeObserver(self, forKeyPath: "currentItem.loadedTimeRanges")
    }
    
    //MARK: - KVO

    public override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {

        //this is when the player is ready and rendering frames
        guard keyPath == "currentItem.loadedTimeRanges" else { return }
        view.activityIndicatorView?.stopAnimating()
        guard let duration = player.currentItem?.duration else { return }
        let seconds = CMTimeGetSeconds(duration)

        guard !seconds.isNaN else { return }
        let secondsText = String(format: "%02d", Int(seconds.truncatingRemainder(dividingBy: 60)))
        let minutesText = String(format: "%02d", Int(seconds) / 60)
        view.videoLengthLabel.text = "\(minutesText):\(secondsText)"
    }
}

// MARK: - Public Methods
public extension VideoPlayer {

    func play() { status = .play }

    func pause() { status = .pause }

    func playVideo(with event: Event, isAutoStart: Bool = true) {
        self.event = event
        if isAutoStart { play() }
    }
}

// MARK: - Private Methods
extension VideoPlayer {
    private func trackTime(with player: AVPlayer) -> Any {
        player
            .addPeriodicTimeObserver(
                forInterval: CMTime(value: 1, timescale: 2),
                queue: .main) { (progressTime) in
                    let seconds = CMTimeGetSeconds(progressTime)
                    let secondsString = String(format: "%02d", Int(seconds.truncatingRemainder(dividingBy: 60)))
                    let minutesString = String(format: "%02d", Int(seconds / 60))

                    self.view.currentTimeLabel.text = "\(minutesString):\(secondsString)"
                    self.delegate?.playerDidUpdateTime(player: self)

                    //lets move the slider thumb
                    if let duration = player.currentItem?.duration, duration.value != 0 {
                        let durationSeconds = CMTimeGetSeconds(duration)
                        self.view.videoSlider.value = seconds / durationSeconds
                    }
        }
    }
}

// MARK: - State
public extension VideoPlayer {
    enum State {
        /// The player does not have any media to play
        case idle
        /// The player is not able to immediately play from its current position. This state typically occurs when more data needs to be loaded
        case buffering
        /// The player is able to immediately play from its current position.
        case ready
        /// The player has finished playing the media
        case ended
        /// Indicates that the player can no longer play.
        case failed
    }
}

// MARK: - Delegate
public protocol PlayerDelegate: AnyObject {
    func playerDidUpdatePlaying(player: VideoPlayer)
    func playerDidUpdateTime(player: VideoPlayer)
}
