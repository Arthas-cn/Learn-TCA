# Effect 与依赖

对照源码：`TCA/Counter/CounterFeature.swift`、`TCA/Counter/NumberFactClient.swift`、`TCA/Contacts/AddContact/AddContactFeature.swift`

`Reduce` 里的 `switch` 本身是同步的。它立刻改状态，然后返回一个 `Effect`，表示「接下来还要做什么」。

- 没有后续工作：`return .none`
- 有异步工作：`return .run { send in ... }`

## 请求数字事实

点 Fact 时，数字还没有回来，界面要先进入加载中。

```swift
case .factButtonTapped:
    state.fact = nil
    state.isLoading = true
    return .run { [count = state.count] send in
        try await send(.factResponse(numberFact.fetch(count)))
    }
```

这里有两个动作，故意分开：

1. `.factButtonTapped` 同步把 `isLoading` 设为 `true`。视图马上能显示进度。
2. `.factResponse` 等请求结束后再进来，写入 `fact`，关掉加载标记。

`[count = state.count]` 把发出请求那一刻的数字捕获进 Effect。请求在飞的时候用户即使又点了加号，这次请求仍然对应旧数字。

Effect 里通过 `send` 把结果送回同一个 `Reduce`。结果仍然走同一个 `switch`，不会直接改状态。

## 取消

定时器是一个会一直 `send` 的 Effect：

```swift
return .run { send in
    for await _ in clock.timer(interval: .seconds(1)) {
        await send(.timerTick)
    }
}
.cancellable(id: CancelID.timer)
```

`.cancellable(id:)` 给这个任务一个身份。再次点按钮时：

```swift
return .cancel(id: CancelID.timer)
```

同一个 id 的任务被取消，循环结束，不会再有 `.timerTick`。

`ifLet` 在子功能的状态变成 `nil` 时，取消的也是这种 Effect：子功能的 `Reduce` 用 `.run` 启动、还没结束的任务。SwiftUI 的动画、转场、视图上的 `.task` 不在这次取消里。

联系人的保存 Effect 很短，发出 delegate 并 `dismiss` 后就结束了，通常等不到被取消。取消真正起作用的是子界面还开着时启动的长任务，比如请求还没回来，用户已经把 sheet 滑掉。任务被取消后，就不能再 `send` 动作回来改一块已经不存在的子状态。

## 依赖

Effect 里用到的时钟、网络，不在功能内部直接创建。功能只声明自己需要什么：

```swift
@Dependency(\.continuousClock) var clock
@Dependency(\.numberFact) var numberFact
```

`NumberFactClient` 是网络这一项的具体形状：一个「传入数字、异步返回字符串」的函数。正式运行时的实现写在 `liveValue` 里，用 `URLSession` 请求 `numbersapi.com`。

测试可以把 `numberFact` 换成固定返回值，把 `continuousClock` 换成 `TestClock`，不用真的等待一秒或访问网络。

## dismiss 也是一个依赖

`AddContactFeature` 里的 `dismiss` 不是它自己创建的。父功能用展示用的 `ifLet` 把子功能嵌进来时，库把这个依赖注入进去。

子功能调用 `await self.dismiss()`，等于请父功能把当前弹出状态置为 `nil`。子功能因此可以关掉自己所在的 sheet，同时不用知道父功能叫 `ContactsFeature`。

展示用的 `ifLet` 才会注入 `dismiss`。普通可选子功能上的 `ifLet` 没有系统弹窗可以关，也就没有这个依赖。两种 `ifLet` 的差别见 [ifLet：可选的子功能](05-ifLet可选子功能.md)。
