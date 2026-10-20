# TCA 学习笔记

这些笔记按当前工程里的代码来写，顺序就是建议的阅读顺序。每篇只讲一件事，并标明对应的源文件。

## 阅读顺序

1. [一个功能的三件套](01-一个功能的三件套.md)：State、Action、Reducer、Store
2. [Effect 与依赖](02-Effect与依赖.md)：异步工作、取消、`@Dependency`
3. [组合](03-组合.md)：为什么要嵌成一棵树，三种接法怎么选
4. [Scope：同时存在的子功能](04-Scope同时存在的子功能.md)：两个计数器页签
5. [ifLet：可选的子功能](05-ifLet可选子功能.md)：子状态时有时无
6. [@Presents 与系统弹窗](06-Presents与系统弹窗.md)：sheet、alert 为什么要这个宏
7. [多个目的地](07-多个目的地.md)：用一个枚举表示互斥的弹出界面
8. [Delegate：父子通信](08-Delegate父子通信.md)：子功能怎样把结果交还给父功能
9. [自定义弹层](09-自定义弹层.md)：自己画的遮罩不用 `@Presents`

## 工程里的两棵功能树

当前能运行的是联系人：

```text
ContactsFeature
 ├── AddContactFeature     添加联系人 sheet，有值才存在
 └── AlertState            删除确认框，有值才存在
```

入口在 `TCA/TCAApp.swift`。

另一棵树留在工程里，没有接到入口上：

```text
AppFeature
 ├── CounterFeature        页签 1，一直存在
 └── CounterFeature        页签 2，一直存在
```

对应文件：

| 文件 | 角色 |
|---|---|
| `TCA/CounterFeature.swift` | 叶子功能：状态、动作、Effect、取消 |
| `TCA/NumberFactClient.swift` | 依赖的具体实现 |
| `TCA/AppFeature.swift` | `Scope` 组合两个计数器 |
| `TCA/Contact.swift` | 放进 State 的模型 |
| `TCA/AddContactFeature.swift` | 子功能，通过 delegate 上报结果 |
| `TCA/ContactsFeature.swift` | `ifLet`、`@Presents`、`Destination` |
| `TCA/ContactsView.swift` | 用 `scope` 把子 store 交给 sheet 和 alert |
