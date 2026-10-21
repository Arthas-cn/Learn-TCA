//
//  ContactDetailView.swift
//  TCA
//
//  堆栈的一层。它只拿到 ContactDetailFeature 的 Store，读不到联系人列表。
//

import ComposableArchitecture
import SwiftUI

struct ContactDetailView: View {
    /// 要写 `$store.scope` 把 alert 交给系统弹窗，所以用 `@Bindable`。
    @Bindable var store: StoreOf<ContactDetailFeature>

    var body: some View {
        Form {
            Button("Edit") {
                store.send(.editButtonTapped)
            }
            Button("Delete") {
                store.send(.deleteButtonTapped)
            }
        }
        .navigationTitle(Text(store.contact.name))
        // `\.alert` 是 State 上的确认框。`\.alertAction` 是 Action 上的 case。
        .alert($store.scope(\.alert, action: \.alertAction))
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(
            store: Store(
                initialState: ContactDetailFeature.State(
                    contact: Contact(id: UUID(), name: "Blob")
                )
            ) {
                ContactDetailFeature()
            }
        )
    }
}
