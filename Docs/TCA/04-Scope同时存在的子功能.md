# Scope：同时存在的子功能

对照源码：`TCA/Counter/AppFeature.swift`、`TCA/Counter/AppView.swift`、`TCA/Counter/CounterFeature.swift`

两个计数器页签从进入应用起就都在。关掉应用之前，它们的状态也一直在。这种子功能用 `Scope`。

```swift
var body: some ReducerOf<Self> {
    Scope(state: \.tab1, action: \.tab1) {
        CounterFeature()
    }
    Scope(state: \.tab2, action: \.tab2) {
        CounterFeature()
    }
    Reduce { _, _ in
        .none
    }
}
```

`CounterFeature()` 写了两次。这是同一功能的两个实例，各跑各的 `Reduce`，处理两份互相独立的 `CounterFeature.State`。页签 1 的 `count` 和页签 2 的 `count` 各算各的。

## 一个动作只进入其中一个

用户在页签 1 点「+」。父功能收到的动作是：

```text
.tab1(.incrementButtonTapped)
```

处理顺序：

1. 第一个 `Scope` 发现动作对得上 `\.tab1`，把 `state.tab1` 交给这一份 `CounterFeature` 的 `Reduce`。`count` 加 1。
2. 第二个 `Scope` 发现动作对不上 `\.tab2`，什么也不做。
3. 最下面父功能自己的 `Reduce` 收到同一个动作。现在没有跨页签的逻辑，返回 `.none`。

点页签 2 时反过来。两个 `Scope` 都会被问到，只有路径匹配的那一份 `CounterFeature` 会跑自己的 `Reduce`。

## 视图只持有一个 Store

`AppView` 的参数是 `StoreOf<AppFeature>`。每个页签再切出自己的计数器 Store：

```swift
CounterView(store: store.scope(\.tab1, action: \.tab1))
CounterView(store: store.scope(\.tab2, action: \.tab2))
```

`CounterView` 仍然只认识 `StoreOf<CounterFeature>`。它不知道自己位于哪一个页签。

应用入口的「计数器」打开的就是这一棵树。两个页签如果各自 `Store(initialState: CounterFeature.State())`，动作不会进入 `AppFeature` 的 `body`，页签之间以后也无法协作。

## 父功能什么时候才写自己的逻辑

父功能自己的 `Reduce` 为空，表示这些子功能被放在一起，但彼此不协作。

如果产品要求「页签 1 点加号时，页签 2 也加一」，就在父功能的 `Reduce` 里增加分支，改 `state.tab2`。计数器本身仍然只认识自己的 `count`，不需要知道还有另一个页签。

## 和 ifLet 的分界

`Scope` 要求那份子状态一直存在，所以 `tab1` 的类型是 `CounterFeature.State`，不是可选值。

子功能会消失、再出现时，用 [ifLet](05-ifLet可选子功能.md)。页签不需要 `dismiss`，也没有「滑掉之后取消任务」这一层，因为这块状态不会变成 `nil`。
