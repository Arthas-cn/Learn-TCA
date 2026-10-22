# @Presents 与系统弹窗

对照源码：`TCA/Contacts/ContactsFeature.swift`、`TCA/Contacts/ContactsView.swift`

`@Presents` 配合 SwiftUI 的系统展示：`.sheet`、`.alert`、`.popover`、`.fullScreenCover`、`.navigationDestination`。

这些 API 的共同点是，用户可以不经过你的按钮就把界面关掉：下滑 sheet，或者点 alert 外面。

## 它在状态上加了什么

```swift
@Presents var destination: Destination.State?
```

表面上仍然像一个可选值。`nil` 表示没有弹出，有值表示正在弹出某一个目的地。

宏把它包成带身份的展示状态。这份身份用来区分「这一次弹出」，这样关闭时能取消这一次启动的 Effect，而不会误伤下一次弹出。配合 `@ObservableState` 时用这个宏，因为它和 `@PresentationState` 属性包装器不能写在一起。

动作也多了一层 `PresentationAction`：

```swift
case destinationAction(PresentationAction<Destination.Action>)
```

只有两种情况：

- `.presented(子动作)`：sheet 或 alert 还开着，里面发生了一件事
- `.dismiss`：界面被关掉了。来源包括下滑、点外部、以及子功能调用 `dismiss`

## 视图把 Binding 交给系统

```swift
.sheet(
    item: $store.scope(\.destination?.addContact, action: \.destinationAction.addContact)
) { addContactStore in
    NavigationStack {
        AddContactView(store: addContactStore)
    }
}
.alert($store.scope(\.destination?.alert, action: \.destinationAction.alert))
```

`@Bindable var store` 是为了写出 `$store`。系统 modifier 要的是 `Binding<Store?>`：

- 值为 `nil`，界面关闭
- 值从 `nil` 变成有值，界面弹出
- 用户把界面关掉，Binding 的写入变成 `.dismiss`

当前弹出的如果不是 `.addContact`，sheet 那个 Binding 就是 `nil`，sheet 不出现。alert 同理。

## 和普通可选值的差别

普通的 `var popup: RenameFeature.State?` 可以描述「现在有没有这个子功能」，并用普通 `ifLet` 接上子功能的 `body`。

它没有展示身份，也没有 `.dismiss`。SwiftUI 的 `.sheet(item:)` 无法把用户的下滑关闭写回这份状态。自己在 `ZStack` 里画出来的弹层不需要这套集成，用法见 [自定义弹层](09-自定义弹层.md)。

系统 sheet 里面放自定义内容，仍然用 `@Presents`。联系人的添加页就是这样：表单是自己的视图，弹出和下滑关闭是系统的。
