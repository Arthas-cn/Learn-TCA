//
//  AddContactView.swift
//  TCA
//
//  子界面只负责把用户操作翻译成 Action，不在这里改列表。
//

import ComposableArchitecture
import SwiftUI

struct AddContactView: View {
    /// `@Bindable` 让 `$store` 能做出 Binding。
    /// 普通的 `let store` 只能 `send` 和读状态，不能交给 `TextField`。
    @Bindable var store: StoreOf<AddContactFeature>

    var body: some View {
        Form {
            // `$store.contact.name` 是一份指向状态的 Binding。
            // `.sending(\.setName)` 把它改成：用户每输入一个字，就 `send(.setName)`。
            // 状态仍然只由 reducer 修改，视图不直接写 `store.contact.name = ...`。
            TextField("Name", text: $store.contact.name.sending(\.setName))

            Button("Save") {
                store.send(.saveButtonTapped)
            }
        }
        .toolbar {
            ToolbarItem {
                Button("Cancel") {
                    store.send(.cancelButtonTapped)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        AddContactView(
            store: Store(
                initialState: AddContactFeature.State(
                    contact: Contact(id: UUID(), name: "Blob")
                )
            ) {
                AddContactFeature()
            }
        )
    }
}
