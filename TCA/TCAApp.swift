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
            // 当前入口是「多个导航目的地」示例。之前的计数器仍留在工程里。
            ContactsView(
                store: Store(initialState: ContactsFeature.State()) {
                    ContactsFeature()
                        //._printChanges()
                }
            )
        }
    }
}
