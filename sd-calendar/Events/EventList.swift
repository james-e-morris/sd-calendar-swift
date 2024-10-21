import EventKit
import SwiftUI

let CALENDAR_NAME = Config.calendarName

struct EventList: View {
  @Binding var calendar: EKCalendar?  // Make it a binding to allow modification
  let eventStore: EKEventStore
  @Binding var events: [EKEvent]  // Make it a binding to allow modification
  @State private var showNewCalendarAlertModal = false

  struct ModalView: View {
    @Binding var isPresented: Bool  // Controls the presentation state
    let message: String

    var body: some View {
      VStack {
        Text(message)
          .padding()
          .multilineTextAlignment(.center)
        Button("OK") {
          isPresented = false  // Dismiss the modal
        }
        .padding()
      }
      .background(Color.white)
      .cornerRadius(10)
      .shadow(radius: 5)
      .padding()
    }
  }

  var body: some View {
    ScrollView {
      ForEach(events, id: \.eventIdentifier) { event in
        if let index = events.firstIndex(of: event), index > 0 {
          Event(event: event, previousEvent: events[index - 1])
        } else {
          Event(event: event, previousEvent: nil)
        }
      }
    }.onAppear {
      checkAndCreateCalendar()
      loadEvents()
    }.sheet(isPresented: $showNewCalendarAlertModal) {
      ModalView(
        isPresented: $showNewCalendarAlertModal,
        message:
          """
          A new calendar was created in the Calendar app named "\(CALENDAR_NAME)".
          The calendar is used for local sync, but interaction with the events is suggested through this app only.

          You can hide the calendar in your calendar app settings so that the \(CALENDAR_NAME) events don't clog up your personal calendar.

          Happy contesting!
          """
      )
    }
  }

  func checkAndCreateCalendar() {
    if calendar != nil {
      return
    }
    // Check if the calendar exists
    let calendars = eventStore.calendars(for: .event).filter { $0.title == CALENDAR_NAME }
    for cal: EKCalendar in calendars {
      if cal.title == CALENDAR_NAME {
        calendar = cal
        break
      }
    }
    // If the calendar doesn't exist, create it
    if calendar == nil {
      calendar = EKCalendar(for: .event, eventStore: eventStore)
      calendar?.title = CALENDAR_NAME
      calendar?.source = eventStore.defaultCalendarForNewEvents?.source
      calendar?.cgColor = Color.white.cgColor
      do {
        try eventStore.saveCalendar(calendar!, commit: true)
        showNewCalendarAlertModal = true
      } catch {
        print("Error saving calendar: \(error)")
        calendar = eventStore.defaultCalendarForNewEvents
      }
    }
  }

  private func loadEvents() {
    // return if no calendar and log error
    if calendar == nil {
      print("No calendar found")
      return
    }
    let oneYearAgo = Date().addingTimeInterval(-365 * 24 * 3600)
    let oneYearAfter = Date().addingTimeInterval(365 * 24 * 3600)
    let predicate = eventStore.predicateForEvents(
      withStart: oneYearAgo, end: oneYearAfter,
      calendars: [calendar!]
      // calendars: eventStore.calendars(for: .event).filter { $0.title == CALENDAR_NAME }
    )
    let fetchedEvents = eventStore.events(matching: predicate)
    events = fetchedEvents.sorted { $0.startDate < $1.startDate }
  }

}
