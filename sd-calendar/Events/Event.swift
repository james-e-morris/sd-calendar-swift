import EventKit
import SwiftUI

extension Date {
  func formattedDate12hr() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "hh:mm a"  // Use "hh" for 12-hour format
    formatter.locale = Locale(identifier: "en_US_POSIX")  // For consistent AM/PM
    return formatter.string(from: self)
  }
}

struct Event: View {
  let event: EKEvent
  let previousEvent: EKEvent?

  var body: some View {
    VStack {
      if let previousEvent = previousEvent,
        event.startDate >= Date() && previousEvent.endDate < Date()
      {
        Rectangle().frame(height: 2).foregroundColor(.red)
      }
      HStack {
        Text(event.title ?? "-").padding()
        Text(event.startDate.formattedDate12hr()).padding()
        Text("\(Int(event.endDate.timeIntervalSince(event.startDate) / 60)) mins").padding()
      }
    }
  }
}
