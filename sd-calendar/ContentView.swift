import EventKit
import SwiftUI

let CALENDAR_NAME = Config.calendarName

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

struct ContentView: View {
    @State private var calendar: EKCalendar?
    @State private var events: [EKEvent] = []
    @State private var showCreateEventModal = false
    @State private var showNewCalendarAlertModal = false
    @State private var eventTitle = ""
    @State private var eventStartDate = Date()
    @State private var eventEndDate = Date()
    @State private var eventStore = EKEventStore()

    var body: some View {
        VStack {
            EventList(events: events)
            Spacer()
            CreateEventButton(showCreateEventModal: $showCreateEventModal)
                .sheet(isPresented: $showCreateEventModal) {
                    createEventModal
                }
        }
        .onAppear {
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

    private var createEventModal: some View {
        VStack {
            TextField("Event Title", text: $eventTitle)
                .padding()
                .textFieldStyle(RoundedBorderTextFieldStyle())
            DatePicker(
                "Start Date", selection: $eventStartDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .padding()
            .onAppear {
                eventStartDate = Date()  // Set start date to current date and time
            }
            DatePicker(
                "End Date", selection: $eventEndDate, displayedComponents: [.date, .hourAndMinute]
            )
            .padding()
            .onAppear {
                eventEndDate = Date().addingTimeInterval(15 * 60)  // Set end date to start + 15 minutes
            }
            .padding()
            Button(action: {
                createEvent()
                showCreateEventModal = false
            }) {
                Text("Create Event")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .padding()
        }
        .padding()
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
        checkAndCreateCalendar()
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

    private func createEvent() {
        if eventTitle.isEmpty {
            return
        }
        func handleEventAccess(granted: Bool, error: Error?) {
            if granted && error == nil {
                checkAndCreateCalendar()

                // create the event
                let newEvent = EKEvent(eventStore: eventStore)
                newEvent.title = eventTitle
                newEvent.startDate = eventStartDate
                newEvent.endDate = eventEndDate
                newEvent.calendar = calendar
                do {
                    try eventStore.save(newEvent, span: .thisEvent)
                    print("Event saved successfully")
                    events.append(newEvent)  // Add the new event to the events list
                    events.sort { $0.startDate < $1.startDate }  // Sort events by timestamp
                } catch {
                    print("Error saving event: \(error)")
                }
            } else {
                print("Access denied")
                print(error?.localizedDescription ?? "No error")
            }
        }

        if #available(macOS 10.14, *) {
            eventStore.requestFullAccessToEvents(completion: { (granted, error) in
                handleEventAccess(granted: granted, error: error)
            })
        } else {

            eventStore.requestAccess(to: .event) { (granted, error) in
                handleEventAccess(granted: granted, error: error)
            }
        }
    }
}
