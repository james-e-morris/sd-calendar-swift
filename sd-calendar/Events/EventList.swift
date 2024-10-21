import EventKit
import SwiftUI

struct EventList: View {
  let events: [EKEvent]

  var body: some View {
    ScrollView {
      ForEach(events, id: \.eventIdentifier) { event in
        if let index = events.firstIndex(of: event), index > 0 {
          Event(event: event, previousEvent: events[index - 1])
        } else {
          Event(event: event, previousEvent: nil)
        }
      }
    }
  }
}
