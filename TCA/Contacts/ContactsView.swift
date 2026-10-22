//
//  ContactsView.swift
//  TCA
//
//  视图不决定「现在该弹出谁」。它只观察 `destination` 的哪一个 case 有值。
//

import ComposableArchitecture
import SwiftUI

struct ContactsView: View {
    /// `@Bindable` 是为了下面的 `$store.scope(...)`。
    /// `sheet(item:)` 和 `alert` 要的是 `Binding<Store<...>?>`：
    /// 值为 nil 就关闭，有值就弹出，用户关掉界面时 Binding 的 setter 会发 `.dismiss`。
    @Bindable var store: StoreOf<ContactsFeature>
    /// 例子入口传进来的返回动作。单独预览联系人时是 nil，不显示返回按钮。
    @Environment(\.demoBack) private var demoBack

    var body: some View {
        // `\.path` 读的是 State.path。`\.pathAction` 是 Action.pathAction。
        // 用户点返回时，系统把对应元素从 path 移除，并变成 `.pathAction(.popFrom(id:))`。
        NavigationStack(path: $store.scope(\.path, action: \.pathAction)) {
            List {
                ForEach(store.contacts) { contact in
                    HStack {
                        Text(contact.name)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            // 名字不拦截点击，点这一块会落到后面的 NavigationLink，推进详情。
                            .allowsHitTesting(false)
                        Button {
                            store.send(.deleteButtonTapped(id: contact.id))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        // 放在链接里面时，整行都是链接，垃圾桶点不到。
                        // borderless 让 List 把这个按钮当成行里的独立控件。
                        .buttonStyle(.borderless)
                    }
                    .background {
                        // 必须用库提供的 `NavigationLink(state:)`。
                        // 它把这份详情 State 追加进 path，而不是用 SwiftUI 自带的 `init(value:)`。
                        // `.detail` 表示这一层是详情页。点下去会 append 进 path。
                        NavigationLink(
                            state: ContactsFeature.Path.State.detail(
                                ContactDetailFeature.State(contact: contact)
                            )
                        ) {
                            EmptyView()
                        }
                        .opacity(0)
                    }
                }
            }
            // 增删发生在 Reduce 里，按钮的 withAnimation 包不到那次状态变化。
            // 列表观察 contacts：多一行就插入，少一行就删除，动画用系统默认的。
            .animation(.default, value: store.contacts)
            .navigationTitle("Contacts")
            .toolbar {
                if let demoBack {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("返回", action: demoBack)
                    }
                }
                ToolbarItem {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        } destination: { store in
            // 闭包拿到的是 `Path` 的 Store。`store.case` 把它拆开，
            // 每一层是哪种页面，就画出哪种视图。漏掉一个 case，这里会编译失败。
            switch store.case {
            case let .detail(store):
                ContactDetailView(store: store)
            case let .edit(store):
                EditContactView(store: store)
            }
        }
        // 第一个 key path `\.destination?.addContact` 钻的是 State：当前弹出的是不是添加联系人。
        // 第二个 key path `\.destinationAction.addContact` 钻的是 Action：子界面的动作从哪个 case 送回来。
        // 子界面发出 `.setName`，到父功能就变成 `.destinationAction(.presented(.addContact(.setName)))`。
        .sheet(
            item: $store.scope(\.destination?.addContact, action: \.destinationAction.addContact)
        ) { addContactStore in
            NavigationStack {
                AddContactView(store: addContactStore)
            }
        }
        // alert 没有内容闭包。`AlertState` 里已经写好了标题和按钮，
        // 这个 modifier 只负责按那份状态把系统 alert 画出来。
        .alert($store.scope(\.destination?.alert, action: \.destinationAction.alert))
    }
}

#Preview {
    ContactsView(
        store: Store(
            initialState: ContactsFeature.State(
                contacts: [
                    Contact(id: UUID(), name: "Blob"),
                    Contact(id: UUID(), name: "Blob Jr"),
                    Contact(id: UUID(), name: "Blob Sr"),
                ]
            )
        ) {
            ContactsFeature()
        }
    )
}
