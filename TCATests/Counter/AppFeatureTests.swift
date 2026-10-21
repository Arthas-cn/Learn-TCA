//
//  AppFeatureTests.swift
//  TCATests
//
//  两个页签各改各的 count。发到 tab1 的动作不能改到 tab2。
//

import ComposableArchitecture
@testable import TCA
import Testing

@MainActor
struct AppFeatureTests {
    @Test func `tabs are independent`() async {
        let store = TestStore(initialState: AppFeature.State()) {
            AppFeature()
        }

        await store.send(.tab1(.incrementButtonTapped)) {
            $0.tab1.count = 1
        }
        await store.send(.tab2(.incrementButtonTapped)) {
            $0.tab2.count = 1
        }
    }
}
