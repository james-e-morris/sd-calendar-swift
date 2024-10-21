import EventKit
import SwiftUI

struct ContentView: View {
    @State private var calendar: EKCalendar?
    @State private var events: [EKEvent] = []
    @State private var eventStore = EKEventStore()

    var body: some View {
        VStack {
            EventList(calendar: $calendar, eventStore: eventStore, events: $events)
            Spacer()
            CreateEvent(calendar: calendar, eventStore: eventStore, events: $events)
        }
    }
}
