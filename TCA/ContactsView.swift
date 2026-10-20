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

    var body: some View {
        NavigationStack {
            List {
                ForEach(store.contacts) { contact in
                    HStack {
                        Text(contact.name)
                        Spacer()
                        Button {
                            store.send(.deleteButtonTapped(id: contact.id))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        // List 里的 Button 默认会撑满整行，点名字也会触发删除。
                        // borderless 让只有垃圾桶图标响应点击。
                        .buttonStyle(.borderless)
                    }
                }
            }
            .navigationTitle("Contacts")
            .toolbar {
                ToolbarItem {
                    Button {
                        store.send(.addButtonTapped)
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        // 先用 key path 钻进 `destination` 的 `.addContact`。
        // 当前弹出的如果不是添加联系人，这个 Binding 就是 nil，sheet 不出现。
        // `@Reducer` 给枚举加了 `@CasePathable`，所以能写成 `\.destination?.addContact`
        // 这种「可选链进某一个 case」的路径。
        //
        // 第二个参数是动作怎么包回父功能：
        // 子界面发出 `AddContactFeature.Action`，scope 把它嵌成
        // `.destination(.presented(.addContact(...)))`。
        .sheet(
            item: $store.scope(\.destination?.addContact, action: \.destination.addContact)
        ) { addContactStore in
            NavigationStack {
                AddContactView(store: addContactStore)
            }
        }
        // alert 没有内容闭包。`AlertState` 里已经写好了标题和按钮，
        // 这个 modifier 只负责按那份状态把系统 alert 画出来。
        .alert($store.scope(\.destination?.alert, action: \.destination.alert))
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
