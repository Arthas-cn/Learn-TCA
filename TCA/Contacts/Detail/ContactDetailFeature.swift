//
//  ContactDetailFeature.swift
//  TCA
//
//  复刻教程：
//  https://pointfreeco.github.io/swift-composable-architecture/1.10.0/tutorials/composablearchitecture/02-04-navigationstacks
//
//  从联系人列表钻进去的详情页。它只认识自己这一条联系人，
//  删除时通过 delegate 请父功能改列表，再靠 dismiss 把自己从堆栈里弹掉。
//

import ComposableArchitecture
import Foundation

@Reducer
struct ContactDetailFeature {
    @ObservableState
    struct State: Equatable {
        /// 详情页自己的确认框。和列表上的删除确认是两份状态，互不干扰。
        /// 这里不需要带联系人 id：这条详情已经持有 `contact`。
        @Presents var alert: AlertState<Action.Alert>?
        /// 钻进来时由列表拷贝进来。
        /// 编辑页保存后，父功能会把新名字写回这一层，所以是 `var`。详情页自己不改它。
        var contact: Contact
    }

    enum Action {
        /// 状态属性叫 `alert`，动作 case 叫 `alertAction`。
        case alertAction(PresentationAction<Alert>)
        /// 说给父功能听。详情页不直接改 `contacts` 数组。
        case delegate(Delegate)
        case deleteButtonTapped

        enum Alert: Equatable {
            case confirmDeletion
        }

        /// 详情页请父功能再推进一层编辑页。
        case editButtonTapped

        enum Delegate {
            /// 不带 id。父功能从堆栈元素里取出这份 `State`，再读 `contact.id`。
            case confirmDeletion
            /// 请父功能把编辑页压到当前详情的上面。详情页不认识 `path`。
            case edit
        }
    }

    /// `forEach` 集成堆栈时注入这个依赖。
    /// 调用它会把当前这一层从 `path` 里弹出，详情页回到列表。
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .alertAction(.presented(.confirmDeletion)):
                // 先通知父功能删列表，再关闭自己。
                // dismiss 会把这一层从 path 移除，所以要先把删除请求发出去。
                return .run { send in
                    await send(.delegate(.confirmDeletion))
                    await self.dismiss()
                }

            case .alertAction:
                return .none

            case .delegate:
                return .none

            case .editButtonTapped:
                // 不在这里改 path。父功能听到 `.delegate(.edit)` 后，才会 append 编辑页。
                return .send(.delegate(.edit))

            case .deleteButtonTapped:
                state.alert = .confirmDeletion
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alertAction)
    }
}

extension AlertState where Action == ContactDetailFeature.Action.Alert {
    /// 把确认框的文案从 reducer 分支里拿出来，之后测试可以直接比较这个值。
    static let confirmDeletion = Self {
        TextState("Are you sure?")
    } actions: {
        ButtonState(role: .destructive, action: .confirmDeletion) {
            TextState("Delete")
        }
    }
}
