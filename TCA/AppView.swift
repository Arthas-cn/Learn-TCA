//
//  AppView.swift
//  TCA
//
//  整棵计数器树只有一个 Store。每个页签拿到的是从它切出来的子 Store。
//

import ComposableArchitecture
import SwiftUI

struct AppView: View {
    let store: StoreOf<AppFeature>

    var body: some View {
        TabView {
            // 1.10 写 `store.scope(state: \.tab1, action: \.tab1)`。
            // 1.26 去掉了 state 标签。切出来的 Store 只认识 CounterFeature。
            CounterView(store: store.scope(\.tab1, action: \.tab1))
                .tabItem {
                    Text("Counter 1")
                }

            CounterView(store: store.scope(\.tab2, action: \.tab2))
                .tabItem {
                    Text("Counter 2")
                }
        }
    }
}

#Preview {
    AppView(
        store: Store(
            initialState: AppFeature.State(
                tab1: CounterFeature.State(count: 1),
                tab2: CounterFeature.State(count: 10)
            )
        ) {
            AppFeature()
        }
    )
}
