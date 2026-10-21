//
//  EditContactView.swift
//  TCA
//
//  堆栈的另一种页面。它只拿到 EditContactFeature 的 Store，读不到列表，也读不到详情页。
//

import ComposableArchitecture
import SwiftUI

struct EditContactView: View {
    @Bindable var store: StoreOf<EditContactFeature>

    var body: some View {
        Form {
            TextField("Name", text: $store.contact.name.sending(\.setName))

            Button("Save") {
                store.send(.saveButtonTapped)
            }
        }
        .navigationTitle("Edit")
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
        EditContactView(
            store: Store(
                initialState: EditContactFeature.State(
                    contact: Contact(id: UUID(), name: "Blob")
                )
            ) {
                EditContactFeature()
            }
        )
    }
}
