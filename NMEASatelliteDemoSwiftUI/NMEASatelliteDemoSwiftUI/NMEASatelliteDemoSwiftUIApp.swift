// Copyright 2024 Esri
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import ArcGIS
import SwiftUI

@main
struct NMEASatelliteDemoSwiftUIApp: App {
    init() {
        // You must set your API Key or request that the user signs in with an ArcGIS account
        // Uncomment the following line to access ArcGIS location services using an API key.
        // ArcGISEnvironment.apiKey = APIKey("<#API Key#>")
    }
    
    var body: some SwiftUI.Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea(edges: [.top, .horizontal])
        }
    }
}
