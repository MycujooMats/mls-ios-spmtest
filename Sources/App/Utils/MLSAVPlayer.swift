//
// Copyright © 2020 mycujoo. All rights reserved.
//

import Foundation
import AVFoundation

/// A subclass of AVPlayer to improve visibility of such things as seeking states.
class MLSAVPlayer: AVPlayer, MLSAVPlayerProtocol {
    private(set) var isSeeking = false

    /// The current time (in seconds) of the currentItem.
    var currentTime: Double {
        return (CMTimeGetSeconds(currentTime()) * 10).rounded() / 10
    }

    /// The current time (in seconds) that is expected after all pending seek operations are done on the currentItem.
    var optimisticCurrentTime: Double {
        return _seekingToTime ?? currentTime
    }

    /// A variable that keeps track of where the player is currently seeking to. Should be set to nil once a seek operation is done.
    private var _seekingToTime: Double? = nil

    /// The duration (in seconds) of the currentItem. If unknown, returns 0.
    /// - seeAlso: `cmDuration`
    var currentDuration: Double {
        guard let duration = currentItem?.duration else { return 0 }
        let seconds = CMTimeGetSeconds(duration)
        guard !seconds.isNaN else {
            // Live stream
            if let items = currentItem?.seekableTimeRanges {
                if !items.isEmpty {
                    let range = items[items.count - 1]
                    let timeRange = range.timeRangeValue
                    let startSeconds = CMTimeGetSeconds(timeRange.start)
                    let durationSeconds = CMTimeGetSeconds(timeRange.duration)

                    return max(currentTime, Double(startSeconds + durationSeconds))
                }

            }
            return 0
        }

        return seconds
    }

    /// The duration reported by the currentItem, without any further manipulation. Typically, it is better to use `currentDuration`.
    var currentDurationAsCMTime: CMTime? {
        return currentItem?.duration
    }

    private var isSeekingUpdatedAt = Date()

    private let seekDebouncer = Debouncer()

    override func seek(to time: CMTime) {
        self.seek(to: time, toleranceBefore: CMTime.positiveInfinity, toleranceAfter: CMTime.positiveInfinity, debounceSeconds: 0.0, completionHandler: { _ in })
    }

    override func seek(to time: CMTime, completionHandler: @escaping (Bool) -> Void) {
        self.seek(to: time, toleranceBefore: CMTime.positiveInfinity, toleranceAfter: CMTime.positiveInfinity, debounceSeconds: 0.0, completionHandler: completionHandler)
    }

    override func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) {
        self.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, debounceSeconds: 0.0, completionHandler: { _ in })
    }

    override func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        self.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, debounceSeconds: 0.0, completionHandler: completionHandler)
    }

    override func seek(to date: Date) {
        self.seek(to: date, debounceSeconds: 0.0, completionHandler: { _ in })
    }

    override func seek(to date: Date, completionHandler: @escaping (Bool) -> Void) {
        self.seek(to: date, debounceSeconds: 0.0, completionHandler: completionHandler)
    }

    /// By using this method, the actual seek operation is debounced as long as there are more calls to this method coming in under the defined threshold.
    /// - note: `isSeeking` will be set to `true` even when the actual seek operation is still being debounced.
    func seek(to time: CMTime, debounceSeconds: Double, completionHandler: @escaping (Bool) -> Void) {
        self.seek(to: time, toleranceBefore: CMTime.positiveInfinity, toleranceAfter: CMTime.positiveInfinity, debounceSeconds: debounceSeconds, completionHandler: completionHandler)
    }

    /// By using this method, the actual seek operation is debounced as long as there are more calls to this method coming in under the defined threshold.
    /// - note: `isSeeking` will be set to `true` even when the actual seek operation is still being debounced.
    func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, debounceSeconds: Double, completionHandler: @escaping (Bool) -> Void) {
        isSeeking = true
        let dateNow = Date()

        _seekingToTime = (CMTimeGetSeconds(time) * 10).rounded() / 10

        isSeekingUpdatedAt = dateNow

        seekDebouncer.minimumDelay = debounceSeconds
        seekDebouncer.debounce { [weak self] in
            guard let self = self else { return }
            self.super_seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter) { [weak self] b in
                guard let self = self else { return }
                if self.isSeekingUpdatedAt == dateNow {
                    self._seekingToTime = nil
                    self.isSeeking = false
                }
                completionHandler(b)
            }
        }
    }

    /// By using this method, the actual seek operation is debounced as long as there are more calls to this method coming in under the defined threshold.
    /// - note: `isSeeking` will be set to `true` even when the actual seek operation is still being debounced.
    func seek(to date: Date, debounceSeconds: Double, completionHandler: @escaping (Bool) -> Void) {
        isSeeking = true
        let dateNow = Date()

        isSeekingUpdatedAt = dateNow

        seekDebouncer.minimumDelay = debounceSeconds
        seekDebouncer.debounce { [weak self] in
            guard let self = self else { return }
            self.super_seek(to: date) { [weak self] b in
                guard let self = self else { return }
                if self.isSeekingUpdatedAt == dateNow {
                    self.isSeeking = false
                }
                completionHandler(b)
            }
        }
    }

    /// Seek by a relative amount of time on the currentItem.
    /// - note: `isSeeking` will be set to `true` even when the actual seek operation is still being debounced.
    func seek(by amount: Double, toleranceBefore: CMTime, toleranceAfter: CMTime, debounceSeconds: Double, completionHandler: @escaping (Bool) -> Void) {
        let currentDuration = self.currentDuration
        guard currentDuration > 0 else { return }

        isSeeking = true
        let dateNow = Date()

        _seekingToTime = max(0, min(currentDuration - 1, optimisticCurrentTime + amount))

        isSeekingUpdatedAt = dateNow

        seekDebouncer.minimumDelay = debounceSeconds
        seekDebouncer.debounce { [weak self] in
            guard let self = self, let _seekingToTime = self._seekingToTime else { return }

            let seekTo = CMTime(seconds: _seekingToTime, preferredTimescale: 1)

            self.super_seek(to: seekTo, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter) { [weak self] b in
                guard let self = self else { return }

                if self.isSeekingUpdatedAt == dateNow {
                    self._seekingToTime = nil
                    self.isSeeking = false
                }
                completionHandler(b)
            }
        }
    }

    /// Helper to avoid error: Using 'super' in a closure where 'self' is explicitly captured is not yet supported
    private func super_seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime, completionHandler: @escaping (Bool) -> Void) {
        super.seek(to: time, toleranceBefore: toleranceBefore, toleranceAfter: toleranceAfter, completionHandler: completionHandler)
    }

    /// Helper to avoid error: Using 'super' in a closure where 'self' is explicitly captured is not yet supported
    private func super_seek(to date: Date, completionHandler: @escaping (Bool) -> Void) {
        super.seek(to: date, completionHandler: completionHandler)
    }

    /// Replace a current item with another AVPlayerItem that is asynchronously built from a URL.
    /// - parameter item: The item to play. If nil is provided, the current item is removed.
    /// - parameter headers: The headers to attach to the network requests when playing this item
    /// - parameter callback: A callback that is called when the replacement is completed (true) or failed/cancelled (false).
    func replaceCurrentItem(with assetUrl: URL?, headers: [String: String], callback: @escaping (Bool) -> ()) {
        guard let assetUrl = assetUrl else {
            self.replaceCurrentItem(with: nil)
            callback(true)
            return
        }

        let asset = AVURLAsset(url: assetUrl, options: ["AVURLAssetHTTPHeaderFieldsKey": headers, "AVURLAssetPreferPreciseDurationAndTimingKey": true])
        asset.loadValuesAsynchronously(forKeys: ["playable"]) { [weak self] in
            guard let `self` = self else { return }

            var error: NSError?
            let status = asset.statusOfValue(forKey: "playable", error: &error)
            switch status {
            case .loaded:
                let playerItem = AVPlayerItem(asset: asset)
                DispatchQueue.main.async { [weak self] in
                    guard let `self` = self else { return }
                    self.replaceCurrentItem(with: playerItem)
                    callback(true)
                }
            default:
                callback(false)
            }
        }
    }
}