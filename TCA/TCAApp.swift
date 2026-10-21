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
    /// Store 放在 App 上，整个进程只创建一次。
    /// 放在视图的 @State 里时，第一次 push 会让 SwiftUI 把这个视图重建一遍，导航跟着被弹回。
    private let counters = Store(initialState: AppFeature.State()) {
        AppFeature()
            ._printChanges()
    }

    private let contacts = Store(initialState: ContactsFeature.State()) {
        ContactsFeature()
    }

    var body: some Scene {
        WindowGroup {
            DemoList(counters: counters, contacts: contacts)
        }
    }
}

private enum Demo: Equatable {
    case counters
    case contacts
}

/// 入口在例子之间直接切换，不再把联系人推进另一层 NavigationStack。
/// 联系人内部已经有自己的堆栈。外层如果再用 NavigationLink 推进去，
/// 第一次进入时内层注册 navigationDestination，外层会立刻把页面弹回。
private struct DemoList: View {
    let counters: StoreOf<AppFeature>
    let contacts: StoreOf<ContactsFeature>

    @State private var demo: Demo?

    var body: some View {
        if let demo {
            switch demo {
            case .counters:
                NavigationStack {
                    AppView(store: counters)
                        .navigationTitle("计数器")
                        .toolbar {
                            ToolbarItem(placement: .topBarLeading) {
                                Button("返回") { self.demo = nil }
                            }
                        }
                }
            case .contacts:
                ContactsView(store: contacts)
                    .environment(\.demoBack, { self.demo = nil })
            }
        } else {
            NavigationStack {
                List {
                    Button("计数器") { demo = .counters }
                    Button("联系人") { demo = .contacts }
                }
                .navigationTitle("TCA")
            }
        }
    }
}

private struct DemoBackActionKey: EnvironmentKey {
    static let defaultValue: (@MainActor () -> Void)? = nil
}

extension EnvironmentValues {
    var demoBack: (@MainActor () -> Void)? {
        get { self[DemoBackActionKey.self] }
        set { self[DemoBackActionKey.self] = newValue }
    }
}
