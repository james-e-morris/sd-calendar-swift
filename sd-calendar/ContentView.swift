import EventKit
import SwiftUI

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
    private let eventStore = EKEventStore()

    var body: some View {
        VStack {
            ScrollView {
                ForEach(events, id: \.eventIdentifier) { event in
                    VStack {
                        Text(event.title)
                            .padding()
                        Text("Start Time: \(event.startDate)")
                            .padding()
                        Text(
                            "Duration: \(event.endDate.timeIntervalSince(event.startDate)) seconds"
                        )
                        .padding()
                    }
                }
            }
            Spacer()
            Button(action: {
                showCreateEventModal = true
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 30, height: 30)
                    .padding()
            }
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
                    A new calendar was created in the Calendar app named "\(Config.calendarName)".
                    The calendar is used for local sync, but interaction with the events is suggested through this app only.

                    You can hide the calendar in your calendar app settings so that the \(Config.calendarName) events don't clog up your personal calendar.

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
            DatePicker(
                "End Date", selection: $eventEndDate, displayedComponents: [.date, .hourAndMinute]
            )
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

    private func loadEvents() {
        checkAndCreateCalendar()
        let oneYearAgo = Date().addingTimeInterval(-365 * 24 * 3600)
        let oneYearAfter = Date().addingTimeInterval(365 * 24 * 3600)
        let predicate = eventStore.predicateForEvents(
            withStart: oneYearAgo, end: oneYearAfter, calendars: [self.calendar!])
        events = eventStore.events(matching: predicate)
    }

    func checkAndCreateCalendar() {
        if self.calendar != nil {
            return
        }
        let eventStore = EKEventStore()
        // Check if the calendar exists
        let calendars = eventStore.calendars(for: .event)
        var calendar: EKCalendar?
        for cal in calendars {
            if cal.title == Config.calendarName {
                calendar = cal
                break
            }
        }
        // If the calendar doesn't exist, create it
        if calendar == nil {
            calendar = EKCalendar(for: .event, eventStore: eventStore)
            calendar?.title = Config.calendarName
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
        self.calendar = calendar
    }

    private func createEvent() {
        func handleEventAccess(granted: Bool, error: Error?) {
            if granted && error == nil {
                // get or create the calendar
                checkAndCreateCalendar()

                // create the event
                let newEvent = EKEvent(eventStore: eventStore)
                newEvent.title = eventTitle
                newEvent.startDate = eventStartDate
                newEvent.endDate = eventEndDate
                newEvent.calendar = eventStore.defaultCalendarForNewEvents
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
