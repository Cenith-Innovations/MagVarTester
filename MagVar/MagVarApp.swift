// ********************** MagVarApp *********************************
// * Copyright © Cenith Innovations, LLC - All Rights Reserved
// * Created on 2/18/21, for MagVar
// * Matthew Elmore <matt@cenithinnovations.com>
// * Unauthorized copying of this file is strictly prohibited
// ********************** MagVarApp *********************************


import SwiftUI

@main
struct MagVarApp: App {
    
    @ObservedObject var parameters = AircraftParametersController.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
