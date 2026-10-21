//
//  Contact.swift
//  TCA
//
//  对应教程：Meet the Composable Architecture
//  Navigation / Multiple presentation destinations（1.10.0）的前置模型。
//

import Foundation

/// 列表里的一条联系人。
///
/// TCA 里放进 `State` 的模型几乎都要 `Equatable`：
/// `TestStore` 靠前后状态是否相等来判断 reducer 有没有改对，
/// SwiftUI 也靠它跳过不必要的刷新。
///
/// `Identifiable` 是给 `IdentifiedArrayOf` 和 `ForEach` 用的。
/// `IdentifiedArray` 按 `id` 做插入、删除和 diff，所以 id 必须稳定，
/// 不能每次渲染都新生成一个 UUID。
struct Contact: Equatable, Identifiable {
    let id: UUID
    var name: String
}
