//
//  EditContactFeature.swift
//  TCA
//
//  导航堆栈上的第二种页面：编辑已有联系人的名字。
//  它和详情页一样不认识列表。保存时只通过 delegate 把新联系人交还给父功能。
//

import ComposableArchitecture

@Reducer
struct EditContactFeature {
    @ObservableState
    struct State: Equatable {
        /// 从详情页拷贝进来的草稿。文本框改的是这份拷贝，列表要等保存后才变。
        var contact: Contact
    }

    enum Action {
        case cancelButtonTapped
        case delegate(Delegate)
        case saveButtonTapped
        case setName(String)

        enum Delegate {
            /// 上报改完的联系人。id 不变，变的是 name。
            case saved(Contact)
        }
    }

    /// `forEach` 集成堆栈时注入。调用它会把当前这一层从 `path` 里弹出，回到详情。
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelButtonTapped:
                return .run { _ in
                    await self.dismiss()
                }

            case .delegate:
                return .none

            case .saveButtonTapped:
                // 先把草稿捕获进 Effect。dismiss 会把这一层从 path 移除，之后就读不到 contact 了。
                return .run { [contact = state.contact] send in
                    await send(.delegate(.saved(contact)))
                    await self.dismiss()
                }

            case let .setName(name):
                state.contact.name = name
                return .none
            }
        }
    }
}
