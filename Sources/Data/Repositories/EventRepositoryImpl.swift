//
// Copyright © 2020 mycujoo. All rights reserved.
//

import Foundation
import Moya


class EventRepositoryImpl: BaseRepositoryImpl, EventRepository {
    let ws: WebSocketConnection

    init(api: MoyaProvider<API>, ws: WebSocketConnection) {
        self.ws = ws

        super.init(api: api)
    }

    func fetchEvent(byId id: String, updateId: String?, callback: @escaping (Event?, Error?) -> ()) {
        _fetch(.eventById(id: id, updateId: updateId), type: DataLayer.Event.self) { (event, err) in
            callback(event?.toDomain, err)
        }
    }
    
    func fetchEvents(pageSize: Int?, pageToken: String?, status: [ParamEventStatus]?, orderBy: ParamEventOrder?, callback: @escaping ([Event]?, String?, String?, Error?) -> ()) {
            _fetch(
                .events(
                    pageSize: pageSize,
                    pageToken: pageToken,
                    status: status?.map { DataLayer.ParamEventStatus.fromDomain($0) },
                    orderBy: orderBy != nil ? DataLayer.ParamEventOrder.fromDomain(orderBy!) : nil),
                type: DataLayer.EventWrapper.self
        ) { (wrapper, err) in
            // TODO: Return the pagination tokens as well
            callback(wrapper?.events.map { $0.toDomain }, wrapper?.nextPageToken, wrapper?.previousPageToken, err)
        }
    }

    func startEventUpdates(for id: String, pseudoUserId: String, callback: @escaping (EventRepositoryEventUpdate) -> ()) {
        // Do an initial event fetch, and upon completion (regardless of failure or success) start subscribing.
        fetchEvent(byId: id, updateId: nil) { [weak self] (initialEvent, nil) in
            if let initialEvent = initialEvent {
                callback(.eventUpdate(event: initialEvent))
            }

            self?.ws.subscribe(eventId: id, sessionId: pseudoUserId) { [weak self] update in
                switch update {
                case .eventTotal(let total):
                    callback(.eventLiveViewers(amount: total))
                case .eventUpdate(let updateId):
                    // Fetch the event again and do the callback after that.
                    self?.fetchEvent(byId: id, updateId: updateId, callback: { updatedEvent, _ in
                        if let updatedEvent = updatedEvent {
                            callback(.eventUpdate(event: updatedEvent))
                        }
                    })
                }
            }
        }
    }
    
    func stopEventUpdates(for id: String) {
        ws.unsubscribe(eventId: id)
    }
}