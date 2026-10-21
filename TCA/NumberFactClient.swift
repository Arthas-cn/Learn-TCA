//
//  NumberFactClient.swift
//  TCA
//
//  Created by Arthas on 2026/08/13.
//

import ComposableArchitecture
import Foundation

/// 计数器向外界要的能力：传入一个数字，异步拿回一句描述。
/// 功能只依赖这个形状。真正的 URLSession 写在 `liveValue` 里，测试里会把 `fetch` 换成固定字符串。
struct NumberFactClient {
    var fetch: (Int) async throws -> String
}

extension NumberFactClient: DependencyKey {
    static let liveValue = Self(
        fetch: { number in
            let (data, _) = try await URLSession.shared
                .data(from: URL(string: "http://numbersapi.com/\(number)")!)
            return String(decoding: data, as: UTF8.self)
        },
    )
}

extension DependencyValues {
    var numberFact: NumberFactClient {
        get { self[NumberFactClient.self] }
        set { self[NumberFactClient.self] = newValue }
    }
}
