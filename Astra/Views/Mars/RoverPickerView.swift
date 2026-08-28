import SwiftUI

struct RoverPickerView: View {
    @Binding var selection: Rover

    var body: some View {
        Picker("Rover", selection: $selection) {
            ForEach(Rover.allCases) { rover in
                Text(rover.title).tag(rover)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    @Previewable @State var rover = Rover.curiosity
    RoverPickerView(selection: $rover).padding()
}
