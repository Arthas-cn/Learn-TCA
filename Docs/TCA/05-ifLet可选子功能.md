# ifLet：可选的子功能

对照源码：`TCA/ContactsFeature.swift`、`TCA/AddContactFeature.swift`

`ifLet` 用于父状态里的一份可选子状态。有值时把子 reducer 接上，值为 `nil` 时子 reducer 不运行。

系统弹窗是最常见的场景，因为 sheet 和 alert 都是「现在没有，点一下才有」。它也用于页内暂时出现的区域，比如点中一行后才展开的编辑器。是不是模态，由视图决定；`ifLet` 只看这份状态是不是可选的。

## 两种 ifLet

库里有两个重载，参数不一样。

普通可选子功能，状态是 `Child.State?`，动作是 `Child.Action`：

```swift
.ifLet(\.popup, action: \.popup) {
    RenameFeature()
}
```

它保证三件事：

1. 子状态是 `nil` 时，不跑子 reducer。
2. 子 reducer 先跑，父 reducer 后跑。父功能如果先把子状态清掉，子功能就看不到自己的状态了。
3. 子状态变成 `nil` 时，取消这个子功能还在跑的 Effect。

系统展示用的是另一个重载。状态来自 `@Presents` 的 `\. $destination`，动作是 `PresentationAction`：

```swift
.ifLet(\.$destination, action: \.destination)
```

它在上面三件事之外，还会注入 `dismiss`，并和 `.sheet`、`.alert` 的关闭动作配合。这一层写在 [@Presents 与系统弹窗](06-Presents与系统弹窗.md)。

`ContactsFeature` 用的是第二种。`Destination` 是 `@Reducer enum`，宏已经生成了它的 reducer，所以这个重载不用再写 `{ Destination() }`。

## 它在功能树里的位置

```text
ContactsFeature.body
 ├── Reduce                         父功能自己的 switch
 └── ifLet(\.$destination, ...)     外层连接器
      └── Destination
           ├── addContact            AddContactFeature，真正的子 reducer
           └── alert                 AlertState，没有子 reducer
```

一次动作先进入 `ifLet`。它决定要不要调用子 reducer，然后再调用下面的父 `Reduce`。

`ContactsFeature` 是父功能。里面的 `Reduce { }` 是父功能自己的逻辑。`AddContactFeature` 是子功能。`ifLet` 是连接器，不是第三份功能。

## 点 Save 时两边各做什么

子功能收到 `.saveButtonTapped`，返回一个 Effect：先发出 `delegate(.saveContact)`，再 `dismiss`。

同一个动作传到父功能时，已经被包成：

```text
.destination(.presented(.addContact(.saveButtonTapped)))
```

父功能的 `switch` 没有为 `saveButtonTapped` 写分支，落到 `case .destination`，返回 `.none`。

随后 Effect 把 `delegate` 送回来。父功能这次匹配到：

```swift
case let .destination(.presented(.addContact(.delegate(.saveContact(contact))))):
    state.contacts.append(contact)
    return .none
```

名字怎样输入，是子功能的事。放进列表，是父功能的事。

## 如果要给 saveButtonTapped 写分支

父功能里要匹配包好的那一层：

```swift
case .destination(.presented(.addContact(.saveButtonTapped))):
    guard case .addContact(let draft) = state.destination else {
        return .none
    }
    state.contacts.append(draft.contact)
    return .none
```

这个分支要写在 `case .destination` 前面。兜底分支写在前面的话，具体分支永远匹配不到。

这个时刻动作本身不带联系人，草稿在 `state.destination` 里。现有代码已经在 `delegate(.saveContact)` 里追加列表。两个分支都追加的话，同一个人会进列表两次。保存留在 delegate 那个分支。

## 关闭时取消的是哪种 Effect

子状态变成 `nil` 后，`ifLet` 取消的是子 reducer 返回的、还没结束的 TCA `Effect`。说明和定时器的例子在 [Effect 与依赖](02-Effect与依赖.md)。
