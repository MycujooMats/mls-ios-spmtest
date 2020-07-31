//
// Copyright © 2020 mycujoo. All rights reserved.
//

import Foundation


class GetEventUpdatesUseCase {
    private let eventRepository: EventRepository

    init(eventRepository: EventRepository) {
        self.eventRepository = eventRepository
    }

    func start(id: String, completionHandler: @escaping (EventUpdate) -> ()) {
        eventRepository.startEventUpdates(for: id) { update in
            switch update {
            case .eventTotal(let total):
                completionHandler(.eventTotal(total: total))
            case .eventUpdate(let updatedEvent):
                // TODO: Compare the updatedEvent with some properties of the current event (which may have to be an input param of this method).
                // That way, we don't do an update callback on every property change.
                completionHandler(.eventUpdate(event: updatedEvent))
            }
        }
    }

    func stop(id: String) {
        eventRepository.stopEventUpdates(for: id)
    }
}

extension GetEventUpdatesUseCase {
    enum EventUpdate {
        case eventTotal(total: Int)
        case eventUpdate(event: Event)
    }
}
