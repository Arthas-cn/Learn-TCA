//
//  ContactsFeature.swift
//  TCA
//
//  复刻教程：
//  https://pointfreeco.github.io/swift-composable-architecture/1.10.0/tutorials/composablearchitecture/02-02-multipledestinations
//
//  这一课要解决的问题：一个父功能要弹出很多个子界面时，领域该怎么建。
//  示例是联系人列表，可以弹出「添加联系人」sheet，也可以弹出「确认删除」alert。
//  这两种界面互斥，同一时刻只能出现一个。
//
//  当前工程依赖的是 TCA 1.26。1.10 教程里的两处写法后来改了名字，行为一样：
//  - `@Reducer(state: .equatable)` 改为在下面用 extension 声明 `Destination.State: Equatable`
//  - `$store.scope(state: \.destination?.addContact, action: \.destination.addContact)`
//    改为 `$store.scope(\.destination?.addContact, action: \.destination.addContact)`
//

import ComposableArchitecture
import Foundation

@Reducer
struct ContactsFeature {
    @ObservableState
    struct State: Equatable {
        /// 联系人集合。`IdentifiedArrayOf` 是带 id 的数组：
        /// 按下标遍历，按 id 删除，SwiftUI 的 `ForEach` 也能直接用。
        var contacts: IdentifiedArrayOf<Contact> = []

        /// 当前弹出的目的地。可选值表示「现在没有弹出任何东西」。
        ///
        /// `@Presents` 把这个属性包成 `PresentationState`。
        /// 它比普通 `Optional` 多记一份「这次展示的身份」，
        /// `ifLet` 靠这个身份取消过期 Effect、注入 `dismiss`，并在关闭时把值清成 nil。
        /// 配合 `@ObservableState` 时不能手写 `@PresentationState` 属性包装器，要用这个宏。
        ///
        /// 为什么不用两个可选值
        /// `addContact: AddContactFeature.State?` 和 `alert: AlertState?` 各自都能为 nil，
        /// 组合数是 2^n。其中合法的只有「全关」和「恰好打开一个」：
        /// - 2 个可选值：4 种组合，1 种非法（两个同时有值）
        /// - 3 个可选值：8 种组合，4 种非法
        /// - 4 个可选值：16 种组合，11 种非法
        /// 收成一个可选枚举后，编译器保证同一时刻最多只有一个 case 有值。
        @Presents var destination: Destination.State?
    }

    enum Action {
        case addButtonTapped
        case deleteButtonTapped(id: Contact.ID)

        /// 子界面发生的所有动作，都从这一个 case 进来。
        /// `PresentationAction` 只有两种：
        /// - `.presented(Destination.Action)`：子功能自己的动作
        /// - `.dismiss`：界面被关掉（下滑 sheet、点 alert 外面、或调用 dismiss 依赖）
        case destination(PresentationAction<Destination.Action>)

        /// Alert 按钮回传的动作。它不属于某个子 reducer，只是按钮被点了之后父功能要做的事。
        /// `AlertState` 要求这个类型 `Equatable`，这样整棵状态可以比较、可以写测试。
        enum Alert: Equatable {
            case confirmDeletion(id: Contact.ID)
        }
    }

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .addButtonTapped:
                // 打开 sheet：把 destination 指到 `.addContact`，并给它一份空草稿。
                // 视图里的 `.sheet(item:)` 观察到这个值从 nil 变成有值，就会弹出。
                print("111111")
                state.destination = .addContact(
                    AddContactFeature.State(
                        contact: Contact(id: UUID(), name: "")
                    )
                )
                return .none

            case let .destination(.presented(.addContact(.delegate(.saveContact(contact))))):
                // 动作被包了三层，从外往里读：
                // 1. `.destination`：发生在某个弹出界面里
                // 2. `.presented(.addContact(...))`：具体是添加联系人，而不是 alert
                // 3. `.delegate(.saveContact)`：子功能说「请保存」
                //
                // 父功能只负责自己的列表。关闭 sheet 由子功能里的 `dismiss()` 完成，
                // 所以这里不用再写 `state.destination = nil`。
                print("4444")
                state.contacts.append(contact)
                return .none

            case let .destination(.presented(.alert(.confirmDeletion(id: id)))):
                // 用户点了 alert 上的 Delete。
                // `AlertState` 是「点一次就结束」的临时界面：`ifLet` 收到按钮动作后会自动把
                // `destination` 置 nil，这里只删数据。
                // 取消按钮不用建模。系统的 Cancel 会走 `.dismiss`，落进下面的兜底分支。
                state.contacts.remove(id: id)
                return .none

            case .destination:
                // 其余弹出动作：子功能内部的 `setName`、关闭、alert 的取消。
                // 父功能没有额外工作，返回 `.none`。
                print("其余弹出动作：子功能内部的 `setName`、关闭、alert 的取消")
                print("555")
                return .none

            case let .deleteButtonTapped(id: id):
                // 还没真正删除。先把 destination 指到 `.alert`，等用户确认。
                // `AlertState` 是值，不是 UIKit/SwiftUI 的命令：标题、按钮、按钮动作都写在状态里。
                // 这样测试时可以直接断言 `state.destination`，不用真的弹出界面。
                state.destination = .alert(
                    AlertState {
                        TextState("Are you sure?")
                    } actions: {
                        ButtonState(role: .destructive, action: .confirmDeletion(id: id)) {
                            TextState("Delete")
                        }
                    }
                )
                return .none
            }
        }
        // `ifLet` 把子 reducer 接到父 reducer 上。展示状态是 nil 时，子 reducer 不运行。
        // 它还做三件父功能自己很容易漏掉的事：
        // 1. 先跑子 reducer，再跑父 reducer。父功能若先把 destination 清掉，子功能就看不到自己的状态了。
        // 2. destination 被置 nil 时，取消这个子界面启动的 Effect。
        // 3. 给子功能注入 `dismiss` 依赖。
        //
        // `Destination` 是 `@Reducer enum`，所以不用像普通子功能那样写出 `{ Destination() }`。
        // 宏已经生成了对应的 reducer，这个重载能从 `Destination.State` 反查出来。
        .ifLet(\.$destination, action: \.destination)
    }
}

extension ContactsFeature {
    /// 所有可以从联系人列表导航过去的界面，合成一个 reducer。
    ///
    /// `@Reducer` 加在 enum 上时，宏会按 case 合成：
    /// - `Destination.State`：每个 case 带上子功能的 `State`（alert 带的是 `AlertState`）
    /// - `Destination.Action`：每个 case 带上子功能的 `Action`
    /// - 一个负责按 case 转发的 `body`
    /// 以后要再加一种弹出界面，只加一个 case，父功能的状态不用再加一个可选值。
    ///
    /// case 里放的是 reducer 类型（`AddContactFeature`），不是 `AddContactFeature.State`。
    /// `State` / `Action` 由宏从这些类型推导。
    ///
    /// `AlertState` 会被库认成临时状态：它没有自己的子 reducer，
    /// 按钮动作直接冒泡给父功能，并且一点击就关闭。
    @Reducer
    enum Destination {
        case addContact(AddContactFeature)
        case alert(AlertState<ContactsFeature.Action.Alert>)
    }
}

/// 1.10 教程写的是 `@Reducer(state: .equatable)`，让宏帮 `Destination.State` 加上 `Equatable`。
/// 这个参数在后续版本里废弃了：编译器已经允许直接给宏生成的嵌套类型补协议。
/// `ContactsFeature.State` 要 `Equatable`，它里面的 `destination` 也必须 `Equatable`。
extension ContactsFeature.Destination.State: Equatable {}
