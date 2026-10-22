# Delegate：父子通信

对照源码：`TCA/Contacts/AddContact/AddContactFeature.swift`、`TCA/Contacts/ContactsFeature.swift`

子功能把结果交还给父功能，用 delegate。子功能不修改父功能的状态，也不引用父功能的类型。

## 子功能只上报事实

```swift
enum Delegate {
    case saveContact(Contact)
}

case .saveButtonTapped:
    return .run { [contact = state.contact] send in
        await send(.delegate(.saveContact(contact)))
        await self.dismiss()
    }
```

保存按钮先把当前草稿捕获出来，再发「请保存这份联系人」，最后请求关闭 sheet。

顺序就按这个来。`dismiss` 会清掉子状态，放在前面的话，Effect 里就读不到 `contact` 了。

子功能自己的 `Reduce` 收到 `.delegate` 时返回 `.none`。这件事是说给父功能听的，子功能不再处理一次。

取消没有 delegate。取消只是把 sheet 关掉，父功能的列表不需要变化，`dismiss` 就够了。

## 父功能看到的是包了三层的动作

```text
.destinationAction(                          发生在某个弹出界面里
  .presented(                          界面还开着
    .addContact(                       这次是添加联系人
      .delegate(.saveContact(contact)) 子功能说：请保存
    )
  )
)
```

父功能拆开这三层，只做自己的事：

```swift
case let .destinationAction(.presented(.addContact(.delegate(.saveContact(contact))))):
    state.contacts.append(contact)
    return .none
```

这里不用写 `state.destination = nil`。后面的 `dismiss()` 会让 `ifLet` 收到 `.dismiss` 并把展示状态清掉。

## 这样拆开之后子功能可以换地方用

`AddContactFeature` 的 State 里只有一份 `Contact` 草稿，Action 里只有改名、保存、取消和 delegate。把它嵌进别的父功能时，那个父功能决定「保存」具体是追加列表、替换某一项，还是发给网络。

父功能如果需要在 `saveButtonTapped` 上直接做事，写法见 [ifLet：可选的子功能](05-ifLet可选子功能.md)。现有的保存入口是 delegate，不要两处都追加。
