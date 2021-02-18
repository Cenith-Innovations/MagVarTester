// ********************** ContentView *********************************
// * Copyright © Cenith Innovations, LLC - All Rights Reserved
// * Created on 2/18/21, for MagVar
// * Matthew Elmore <matt@cenithinnovations.com>
// * Unauthorized copying of this file is strictly prohibited
// ********************** ContentView *********************************


import SwiftUI

// MARK: 👉 This is the main View, I get the data from AircraftParametersController
struct ContentView: View {
    
    @ObservedObject var params = AircraftParametersController.shared
    
    var body: some View {
        VStack {
            RowView(value: $params.magHeading, title: "Mag Heading:")
            RowView(value: $params.trueHeading, title: "True Heading:")
            RowView(value: $params.magneticVariation, title: "Mag Var:")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

// MARK: 👉 This is just to display the data
struct RowView: View {
    
    @Binding var value: Double
    var title: String
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text("\(value)")
        }.padding()
    }
}
