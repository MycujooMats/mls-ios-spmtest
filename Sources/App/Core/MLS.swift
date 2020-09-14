//
// Copyright © 2020 mycujoo. All rights reserved.
//

import Foundation
import AVFoundation
import Moya

fileprivate struct UserDefaultsContracts {
    static let PseudoUserId = "mls_pseudo_user_id"
}

public struct Configuration {
    let seekTolerance: CMTime
    let playerConfig: PlayerConfig

    /// - parameter seekTolerance: The seekTolerance can be configured to alter the accuracy with which the player seeks.
    ///   Set to `zero` for seeking with high accuracy at the cost of lower seek speeds. Defaults to `positiveInfinity` for faster seeking.
    public init(seekTolerance: CMTime = .positiveInfinity, playerConfig: PlayerConfig = PlayerConfig.standard()) {
        self.seekTolerance = seekTolerance
        self.playerConfig = playerConfig
    }
}

/// The class that should be used to interact with MLS components.
/// - note: Make sure to retain an instance of this class as long as you use any of its components.
public class MLS {
    public var publicKey: String
    public let configuration: Configuration

    // TODO: Inject this dependency graph, rather than building it here.

    private lazy var api: MoyaProvider<API> = {
        let authPlugin = AccessTokenPlugin(tokenClosure: { [weak self] _ in
            return self?.publicKey ?? ""
        })
        return MoyaProvider<API>(plugins: [authPlugin])
    }()

    private lazy var ws: WebSocketConnection = {
        return WebSocketConnection()
    }()

    private lazy var pseudoUserId: String = {
        if let v = UserDefaults.standard.string(forKey: UserDefaultsContracts.PseudoUserId) {
            return v
        }
        let v = UUID().uuidString
        UserDefaults.standard.setValue(v, forKey: UserDefaultsContracts.PseudoUserId)
        return v
    }()

    private lazy var timelineRepository: TimelineRepository = {
        return TimelineRepositoryImpl(api: api)
    }()
    private lazy var eventRepository: EventRepository = {
        return EventRepositoryImpl(api: api, ws: ws)
    }()
    private lazy var playerConfigRepository: PlayerConfigRepository = {
        return PlayerConfigRepositoryImpl(api: api)
    }()
    private lazy var arbitraryDataRepository: ArbitraryDataRepository = {
        return ArbitraryDataRepositoryImpl()
    }()

    private lazy var getAnnotationActionsForTimelineUseCase: GetAnnotationActionsForTimelineUseCase = {
        return GetAnnotationActionsForTimelineUseCase(timelineRepository: timelineRepository)
    }()
    private lazy var getEventUseCase: GetEventUseCase = {
        return GetEventUseCase(eventRepository: eventRepository)
    }()
    private lazy var getEventUpdatesUseCase: GetEventUpdatesUseCase = {
        return GetEventUpdatesUseCase(eventRepository: eventRepository)
    }()
    private lazy var getPlayerConfigUseCase: GetPlayerConfigUseCase = {
        return GetPlayerConfigUseCase(playerConfigRepository: playerConfigRepository)
    }()
    private lazy var listEventsUseCase: ListEventsUseCase = {
        return ListEventsUseCase(eventRepository: eventRepository)
    }()
    private lazy var getSVGUseCase: GetSVGUseCase = {
        return GetSVGUseCase(arbitraryDataRepository: arbitraryDataRepository)
    }()

    /// An internally available service that can be overwritten for the purpose of testing.
    private lazy var annotationService: AnnotationServicing = {
        return AnnotationService()
    }()

    private lazy var dataProvider_: DataProvider = {
        return DataProvider(getEventUseCase: getEventUseCase, listEventsUseCase: listEventsUseCase)
    }()

    public init(publicKey: String, configuration: Configuration) {
        if publicKey.isEmpty {
            fatalError("Please insert your publicKey in the MLS component. You can obtain one through https://mls.mycujoo.tv")
        }
        self.publicKey = publicKey
        self.configuration = configuration
    }

    /// Provides a VideoPlayer object.
    /// - parameter event: An optional MLS Event object. If provided, the associated stream on that object will be loaded into the player.
    public func videoPlayer(with event: Event? = nil) -> VideoPlayer {
        let player = VideoPlayer(
            view: VideoPlayerView(),
            player: MLSAVPlayer(),
            getEventUpdatesUseCase: getEventUpdatesUseCase,
            getAnnotationActionsForTimelineUseCase: getAnnotationActionsForTimelineUseCase,
            getPlayerConfigUseCase: getPlayerConfigUseCase,
            getSVGUseCase: getSVGUseCase,
            annotationService: annotationService,
            seekTolerance: configuration.seekTolerance,
            pseudoUserId: pseudoUserId)

        player.playerConfig = configuration.playerConfig
        player.event = event

        return player
    }

    /// Provides a DataProvider object that can be used to retrieve data from the MLS API directly.
    public func dataProvider() -> DataProvider {
        return dataProvider_
    }
}


