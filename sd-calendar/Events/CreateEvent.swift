import EventKit
import SwiftUI

struct CreateEvent: View {
  let calendar: EKCalendar?
  let eventStore: EKEventStore
  @Binding var events: [EKEvent]  // Make it a binding to allow modification
  @State private var showCreateEventModal = false
  @State private var eventTitle = ""
  @State private var eventStartDate = Date()
  @State private var eventEndDate = Date()

  var body: some View {
    Button(action: {
      showCreateEventModal = !showCreateEventModal
    }) {
      Text("+")
    }
    if showCreateEventModal {
      CreateEventModal
    }

  }

  var CreateEventModal: some View {
    VStack {
      TextField("Event Title", text: $eventTitle)
        .textFieldStyle(RoundedBorderTextFieldStyle())
      DatePicker(
        "Start Date", selection: $eventStartDate,
        displayedComponents: [.date, .hourAndMinute]
      )
      .onAppear {
        eventStartDate = Date()  // Set start date to current date and time
      }
      DatePicker(
        "End Date", selection: $eventEndDate, displayedComponents: [.date, .hourAndMinute]
      )
      .onAppear {
        eventEndDate = Date().addingTimeInterval(15 * 60)  // Set end date to start + 15 minutes
      }
      Button(action: {
        createEvent()
        showCreateEventModal = false
      }) {
        Text("Create Event")
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(8)
      }
    }
    .padding()
  }

  private func createEvent() {
    if eventTitle.isEmpty {
      return
    }
    func handleEventAccess(granted: Bool, error: Error?) {
      if granted && error == nil {
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
