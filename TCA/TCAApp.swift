//
//  TCAApp.swift
//  TCA
//
//  Created by Arthas on 2026/08/05.
//

import ComposableArchitecture
import SwiftUI

@main
struct TCAApp: App {
    var body: some Scene {
        WindowGroup {
            CounterView(
                store: Store(initialState: CounterFeature.State()) {
                    CounterFeature()
                        ._printChanges()
                }
            )
        }
    }
}
