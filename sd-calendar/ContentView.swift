import EventKit
import SwiftUI
import UserNotifications

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
    @State private var showNewCalendarModal = false
    @State private var calendar: EKCalendar?
    @State private var eventTitle: String = ""
    @State private var eventStartDate: Date = Date()
    @State private var eventEndDate: Date = Date()

    var body: some View {
        VStack {
            TextField("Event Title", text: $eventTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            DatePicker("Start Date", selection: $eventStartDate)
                .padding()
            DatePicker("End Date", selection: $eventEndDate)
                .padding()
            Button("Create Event") {
                createEvent()
            }
            .padding()
        }.sheet(isPresented: $showNewCalendarModal) {
            ModalView(
                isPresented: $showNewCalendarModal,
                message:
                    """
                    A new calendar was created in the Calendar app named "sd-contest-calendar".
                    The calendar is used for local sync, but interaction with the events is suggested through this app.

                    It is suggested to hide the calendar in your calendar app settings so that the SD Contest Calendar events don't clog up your calendar on top of your own events.

                    Happy contesting!
                    """
            )
        }

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
            if cal.title == "sd-calendar" {
                calendar = cal
                break
            }
        }

        // If the calendar doesn't exist, create it
        if calendar == nil {
            calendar = EKCalendar(for: .event, eventStore: eventStore)
            calendar?.title = "sd-calendar"
            calendar?.source = eventStore.defaultCalendarForNewEvents?.source
            calendar?.cgColor = Color.white.cgColor

            do {
                try eventStore.saveCalendar(calendar!, commit: true)
                showNewCalendarModal = true
            } catch {
                print("Error saving calendar: \(error)")
                calendar = eventStore.defaultCalendarForNewEvents
            }
        }

        self.calendar = calendar
    }

    func createEvent() {
        let eventStore = EKEventStore()

        func handleEventAccess(granted: Bool, error: Error?) {
            if granted && error == nil {
                // get or create the calendar
                checkAndCreateCalendar()

                // create the event
                let event = EKEvent(eventStore: eventStore)
                event.calendar = self.calendar
                event.title = self.eventTitle
                event.startDate = self.eventStartDate
                event.endDate = self.eventEndDate

                let alarm = EKAlarm(relativeOffset: -60 * 30)  // 30 min before
                event.addAlarm(alarm)

                do {
                    try eventStore.save(event, span: .thisEvent)
                    print("Event saved successfully")
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
