import SwiftUI

struct CreateEventButton: View {
  @Binding var showCreateEventModal: Bool

  var body: some View {
    Button(action: {
      showCreateEventModal = true
    }) {
      Text("+")
    }
  }
}
