//
//  CounterFeature.swift
//  TCA
//
//  Created by Arthas on 2026/08/12.
//

import ComposableArchitecture
import Foundation

/// 最小的一份功能：加减数字、每秒自动加一、向网络要一句关于这个数字的事实。
/// 它不认识页签，也不认识联系人。被嵌进 `AppFeature` 时，外面会把它的动作包成 `.tab1(...)` 或 `.tab2(...)`。
@Reducer
struct CounterFeature {
    @ObservableState
    struct State: Equatable {
        var count = 0
        /// 最近一次数字事实。加减或定时器跳动后清空，避免句子还在描述旧数字。
        var fact: String?
        /// 请求还没回来。视图用它决定显示进度圈还是句子。
        var isLoading = false
        var isTimerRunning = false
    }

    enum Action {
        case decrementButtonTapped
        case factButtonTapped
        /// 网络回来之后由 Effect `send` 进来。视图不会直接发这个动作。
        case factResponse(String)
        case incrementButtonTapped
        /// 定时器每跳一次发一次。同样不是按钮直接发的。
        case timerTick
        case toggleTimerButtonTapped
    }

    /// 给「正在跑的定时器 Effect」起的身份。取消时按这个身份找到它。
    enum CancelID { case timer }

    /// 时钟和网络都不在功能内部创建。测试可以换成 TestClock 和固定文案。
    @Dependency(\.continuousClock) var clock
    @Dependency(\.numberFact) var numberFact

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .decrementButtonTapped:
                state.count -= 1
                state.fact = nil
                return .none

            case .factButtonTapped:
                state.fact = nil
                state.isLoading = true
                // 把点击那一刻的数字捕获进 Effect。请求飞行期间用户再点加号，这次请求仍对应旧数字。
                return .run { [count = state.count] send in
                    try await send(.factResponse(numberFact.fetch(count)))
                }

            case let .factResponse(fact):
                state.fact = fact
                state.isLoading = false
                return .none

            case .incrementButtonTapped:
                state.count += 1
                state.fact = nil
                return .none

            case .timerTick:
                state.count += 1
                state.fact = nil
                return .none

            case .toggleTimerButtonTapped:
                state.isTimerRunning.toggle()
                if state.isTimerRunning {
                    // 这个循环会一直 send，直到被同一个 CancelID 取消。
                    return .run { send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.timerTick)
                        }
                    }
                    .cancellable(id: CancelID.timer)
                } else {
                    return .cancel(id: CancelID.timer)
                }
            }
        }
    }
}
