//
// Copyright © 2021 mycujoo. All rights reserved.
//

import Foundation
import UIKit
import MLSSDK
import GoogleCast


class CastIntegrationImpl: NSObject, CastIntegration, GCKLoggerDelegate {
    private static var wasPreviouslyInitialized = false

    weak var videoPlayerDelegate: CastIntegrationVideoPlayerDelegate?
    weak var delegate: CastIntegrationDelegate?

    lazy var appId: String = {
        //        guard let appId = Bundle.mlsResourceBundle?.object(forInfoDictionaryKey: "CastAppId") as? String else {
        //            fatalError("Could not read Cast appId from Info.plist")
        //        }
        return castAppId
    }()

    private var _isCasting = false
    private var _player = CastPlayer()

    init(delegate: CastIntegrationDelegate) {
        self.delegate = delegate

        super.init()
    }

    deinit {
        GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.remove(self)
        GCKCastContext.sharedInstance().sessionManager.remove(self)
    }

    func initialize(_ videoPlayerDelegate: CastIntegrationVideoPlayerDelegate) {
        guard let delegate = delegate else { return }

        self.videoPlayerDelegate = videoPlayerDelegate

        if !CastIntegrationImpl.wasPreviouslyInitialized {
            CastIntegrationImpl.wasPreviouslyInitialized = true

            // This shared instance setup should only be done once in the lifetime of the app.
            let criteria = GCKDiscoveryCriteria(applicationID: appId)
            let options = GCKCastOptions(discoveryCriteria: criteria)
            options.physicalVolumeButtonsWillControlDeviceVolume = true
            GCKCastContext.setSharedInstanceWith(options)
        }

        GCKLogger.sharedInstance().delegate = self
        GCKLogger.sharedInstance().loggingEnabled = false
        GCKLogger.sharedInstance().consoleLoggingEnabled = false
        let logFilter = GCKLoggerFilter()
        logFilter.minimumLevel = .none
        GCKLogger.sharedInstance().filter = logFilter

        GCKCastContext.sharedInstance().sessionManager.add(self)

        switch(GCKCastContext.sharedInstance().castState) {
        case .connected:
            _isCasting = true
        default:
            break
        }

        let castButton = GCKUICastButton(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
        castButton.tintColor = UIColor.gray

        let castButtonParentView = delegate.getCastButtonParentView()
        castButtonParentView.addSubview(castButton)
        let castButtonConstraints = [
            castButton.leftAnchor.constraint(equalTo: castButtonParentView.leftAnchor),
            castButton.rightAnchor.constraint(equalTo: castButtonParentView.rightAnchor),
            castButton.topAnchor.constraint(equalTo: castButtonParentView.topAnchor),
            castButton.bottomAnchor.constraint(equalTo: castButtonParentView.bottomAnchor),
        ]
        for constraint in castButtonConstraints {
            constraint.priority = UILayoutPriority(rawValue: 749)
        }
        NSLayoutConstraint.activate(castButtonConstraints)

        #if DEBUG
        GCKLogger.sharedInstance().delegate = self
        #endif

        _player.initialize()
    }

    func player() -> CastPlayerProtocol {
        return _player
    }

    func isCasting() -> Bool {
        return _isCasting
    }
}

// - MARK: GCKRemoteMediaClientListener

extension CastIntegrationImpl: GCKRemoteMediaClientListener {
    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaStatus: GCKMediaStatus?) {
        _player.updateMediaStatus(mediaStatus)
    }

    func remoteMediaClient(_ client: GCKRemoteMediaClient, didUpdate mediaMetadata: GCKMediaMetadata?) {

    }

    func remoteMediaClientDidUpdateQueue(_ client: GCKRemoteMediaClient) {

    }
}

// - MARK: GCKSessionManagerListener

extension CastIntegrationImpl: GCKSessionManagerListener {
    func sessionManager(_ sessionManager: GCKSessionManager, didStart session: GCKCastSession) {
            switchPlaybackToRemote()
        }

        func sessionManager(_ sessionManager: GCKSessionManager, didResumeCastSession session: GCKCastSession) {
            switchPlaybackToRemote()
        }

        func sessionManager(_ sessionManager: GCKSessionManager, willEnd session: GCKCastSession) {
            // Switch to local BEFORE the session ends, because it gives us a chance to stop playback BEFORE the connection is broken.
            switchPlaybackToLocal()
        }

        func sessionManager(_ sessionManager: GCKSessionManager, didEnd session: GCKCastSession, withError error: Error?) {
            // This should be redundant, but is useful as a safety measure.
            switchPlaybackToLocal()
        }

        func sessionManager(_ sessionManager: GCKSessionManager, didFailToStart session: GCKCastSession, withError error: Error) {
            switchPlaybackToLocal()
        }

        func switchPlaybackToLocal() {
            guard _isCasting else { return }
            _isCasting = false

            _player.stopUpdatingTime()

            GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.remove(self)

            videoPlayerDelegate?.isCastingStateUpdated()
        }

        func switchPlaybackToRemote() {
            guard !_isCasting else { return }
            _isCasting = true

            GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.add(self)

            videoPlayerDelegate?.isCastingStateUpdated()
            
//            if let metadata = GCKCastContext.sharedInstance().sessionManager.currentSession?.remoteMediaClient?.mediaStatus?.mediaInformation?.metadata {
//                _metadataUpdatedSubject.onNext(metadata)
//            }
        }
}

// - MARK: GCKLoggerDelegate

extension CastIntegrationImpl {
    func logMessage(_ message: String, at level: GCKLoggerLevel, fromFunction function: String, location: String) {
        print(function + " - " + message)
    }
}
