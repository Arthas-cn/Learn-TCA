//
//  AddContactFeature.swift
//  TCA
//
//  子功能：用 sheet 弹出的「添加联系人」表单。
//  它不认识联系人列表。保存时只通过 delegate 把结果交还给父功能。
//

import ComposableArchitecture

@Reducer
struct AddContactFeature {
    @ObservableState
    struct State: Equatable {
        /// 正在编辑的草稿。点「+」时由父功能创建一份空联系人塞进来。
        var contact: Contact
    }

    enum Action {
        case cancelButtonTapped
        /// 子功能通知父功能的出口。子功能不直接改父状态。
        case delegate(Delegate)
        case saveButtonTapped
        /// 文本框每改一个字就发一次，由 reducer 写回 `contact.name`。
        case setName(String)

        enum Delegate {
            /// 只上报「请保存这份联系人」。
            /// 取消不需要 delegate：`dismiss` 会把可选的展示状态清成 nil，sheet 自己消失。
            case saveContact(Contact)
        }
    }

    /// `dismiss` 不是子功能自己发明的。
    /// 父功能用 `ifLet` 把子 reducer 嵌进来时，库会注入这个依赖。
    /// 调用它等于向父 store 发送 `PresentationAction.dismiss`，由 `ifLet` 把展示状态置 nil。
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .cancelButtonTapped:
                // 副作用放在 Effect 里。reducer 本身保持同步、可测试。
                return .run { _ in
                    await self.dismiss()
                }

            case .delegate:
                // delegate 是给父功能看的。子功能收到后什么都不做，
                // 否则会和父功能抢同一件事。
                print("33333")
                return .none

            case .saveButtonTapped:
                // 先把当前联系人捕获进 Effect，再发 delegate，最后关掉 sheet。
                // 顺序不能反：dismiss 会清掉子状态，之后就读不到 contact 了。
                print("22222")
                return .run { [contact = state.contact] send in
                    await send(.delegate(.saveContact(contact)))
                    await self.dismiss()
                }

            case let .setName(name):
                print("输入name")
                state.contact.name = name
                return .none
            }
        }
    }
}
