//
// Copyright © 2020 mycujoo. All rights reserved.
//

import Foundation

class ListEventsUseCase {
    private let eventRepository: EventRepository

    init(eventRepository: EventRepository) {
        self.eventRepository = eventRepository
    }

    func execute(pageSize: Int?, pageToken: String?, status: [ParamEventStatus]?, orderBy: ParamEventOrder?, completionHandler: @escaping ([Event]?, String?, String?, Error?) -> ()) {

        eventRepository.fetchEvents(pageSize: pageSize, pageToken: pageToken, status: status, orderBy: orderBy) { (events, nextPageToken, previousPageToken, error) in
            completionHandler(events, nextPageToken, previousPageToken, error)
        }
    }
}
