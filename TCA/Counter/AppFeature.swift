//
//  AppFeature.swift
//  TCA
//
//  两个一直存在的计数器，合成一棵树。
//  对应笔记：Docs/TCA/04-Scope同时存在的子功能.md
//

import ComposableArchitecture

@Reducer
struct AppFeature {
    /// 两份计数器状态从进入应用起就都在，所以是普通字段，不是可选值。
    @ObservableState
    struct State: Equatable {
        var tab1 = CounterFeature.State()
        var tab2 = CounterFeature.State()
    }

    enum Action {
        /// 页签 1 里发生的任何计数器动作，都包在这个 case 里。
        case tab1(CounterFeature.Action)
        case tab2(CounterFeature.Action)
    }

    var body: some ReducerOf<Self> {
        // 每个 Scope 只在动作对得上自己的 case 时，把对应那一份状态交给 CounterFeature。
        Scope(state: \.tab1, action: \.tab1) {
            CounterFeature()
        }
        Scope(state: \.tab2, action: \.tab2) {
            CounterFeature()
        }
        // 父功能自己的逻辑。两个页签目前互不影响，所以这里没有分支。
        Reduce { _, _ in
            .none
        }
    }
}
