//
//  InputSourceObserver.swift
//  CharmingPanel
//
//  Created by kajitani kento on 2025/12/06.
//

import SwiftUI
import AppKit
import Carbon
import ComposableArchitecture
import DependenciesMacros

// MARK: - define dependency interface

@DependencyClient
struct InputSourceObserver {
    var stream: @Sendable () async -> AsyncStream<InputSource> = { .init { _ in } }
    var stop: @Sendable () async -> Void
}

extension DependencyValues {
    var inputSource: InputSourceObserver {
        get { self[InputSourceObserver.self] }
        set { self[InputSourceObserver.self] = newValue }
    }
}

extension InputSourceObserver: DependencyKey, Sendable {
    
    static var liveValue: InputSourceObserver {
        let live = InputSourceObserverLive()
        return .init(
            stream: {
                await live.stream
            },
            stop: {
                await live.stop()
            }
        )
    }
    
    static let previewValue: InputSourceObserver = .init(stream: { .init { _ in } }, stop: {})
}

// MARK: - define live

actor InputSourceObserverLive {
    private var observer: (any NSObjectProtocol)?
    private var continuation: AsyncStream<InputSource>.Continuation?

    init() {}
    
    var stream: AsyncStream<InputSource> {
        startObserving()
        return AsyncStream { continuation in
            self.continuation = continuation
            
            Task {
                await updateCurrent()
            }
        }
    }
    
    func stop() {
        if let observer {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
        continuation?.finish()
        continuation = nil
    }
    
    private func getCurrent() async -> InputSource {
        InputSource.of(await getCurrentInputSourceName())
    }

    @MainActor
    private func getCurrentInputSourceName() -> String {
        guard let source = TISCopyCurrentKeyboardInputSource()?.takeUnretainedValue() else {
            return "Unknown"
        }

        if let namePtr = TISGetInputSourceProperty(source, kTISPropertyLocalizedName) {
            let cfStr = unsafeBitCast(namePtr, to: CFString.self)
            return cfStr as String
        }
        
        return "Unknown"
    }

    private func updateCurrent() async {
        continuation?.yield(await getCurrent())
    }

    private func startObserving() {
        let notificationName = Notification.Name("com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged")
        observer = DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task {
                await self?.updateCurrent()
            }
        }
    }
}

enum InputSource: Sendable {
    // 英数字・ラテン文字系
    case abc
    case french
    case german
    case spanish
    case portuguese
    case italian
    case dutch
    case swedish
    case norwegian
    case danish
    case finnish
    case polish
    case czech
    case hungarian
    case turkish

    // 日本語
    case hiragana
    case katakana

    // アジア言語
    case korean
    case chineseSimplified
    case chineseTraditional
    case thai
    case vietnamese

    // 中東・その他
    case arabic
    case hebrew

    // ヨーロッパ・その他
    case russian
    case greek

    // 不明
    case unknown

    nonisolated static func of(_ name: String) -> Self {
        let lowercasedName = name.lowercased()

        // 英数字・ラテン文字系
        if lowercasedName.contains("us") || name.contains("英数") || lowercasedName.contains("abc") || lowercasedName.contains("u.s.") {
            return .abc
        }
        if lowercasedName.contains("french") || lowercasedName.contains("français") || lowercasedName.contains("francais") {
            return .french
        }
        if lowercasedName.contains("german") || lowercasedName.contains("deutsch") {
            return .german
        }
        if lowercasedName.contains("spanish") || lowercasedName.contains("español") || lowercasedName.contains("espanol") {
            return .spanish
        }
        if lowercasedName.contains("portuguese") || lowercasedName.contains("português") || lowercasedName.contains("portugues") {
            return .portuguese
        }
        if lowercasedName.contains("italian") || lowercasedName.contains("italiano") {
            return .italian
        }
        if lowercasedName.contains("dutch") || lowercasedName.contains("nederlands") {
            return .dutch
        }
        if lowercasedName.contains("swedish") || lowercasedName.contains("svenska") {
            return .swedish
        }
        if lowercasedName.contains("norwegian") || lowercasedName.contains("norsk") {
            return .norwegian
        }
        if lowercasedName.contains("danish") || lowercasedName.contains("dansk") {
            return .danish
        }
        if lowercasedName.contains("finnish") || lowercasedName.contains("suomi") {
            return .finnish
        }
        if lowercasedName.contains("polish") || lowercasedName.contains("polski") {
            return .polish
        }
        if lowercasedName.contains("czech") || lowercasedName.contains("čeština") || lowercasedName.contains("cestina") {
            return .czech
        }
        if lowercasedName.contains("hungarian") || lowercasedName.contains("magyar") {
            return .hungarian
        }
        if lowercasedName.contains("turkish") || lowercasedName.contains("türkçe") || lowercasedName.contains("turkce") {
            return .turkish
        }

        // 日本語
        if name.contains("ひらがな") || lowercasedName.contains("hiragana") {
            return .hiragana
        }
        if name.contains("カタカナ") || lowercasedName.contains("katakana") {
            return .katakana
        }

        // アジア言語
        if lowercasedName.contains("korean") || lowercasedName.contains("hangul") || lowercasedName.contains("한국") {
            return .korean
        }
        if lowercasedName.contains("pinyin") || lowercasedName.contains("simplified chinese") || lowercasedName.contains("简体") || lowercasedName.contains("简化字") {
            return .chineseSimplified
        }
        if lowercasedName.contains("zhuyin") || lowercasedName.contains("traditional chinese") || lowercasedName.contains("繁體") || lowercasedName.contains("繁体") || lowercasedName.contains("注音") {
            return .chineseTraditional
        }
        if lowercasedName.contains("thai") || lowercasedName.contains("ไทย") {
            return .thai
        }
        if lowercasedName.contains("vietnamese") || lowercasedName.contains("tiếng việt") || lowercasedName.contains("tieng viet") {
            return .vietnamese
        }

        // 中東・その他
        if lowercasedName.contains("arabic") || lowercasedName.contains("العربية") {
            return .arabic
        }
        if lowercasedName.contains("hebrew") || lowercasedName.contains("עברית") {
            return .hebrew
        }

        // ヨーロッパ・その他
        if lowercasedName.contains("russian") || lowercasedName.contains("русский") {
            return .russian
        }
        if lowercasedName.contains("greek") || lowercasedName.contains("ελληνικά") || lowercasedName.contains("ellinika") {
            return .greek
        }

        // デフォルト
        return .unknown
    }
    
    var shortLabel: String {
        switch self {
        // 英数字・ラテン文字系
        case .abc: "A"
        case .french: "F"
        case .german: "D"
        case .spanish: "E"
        case .portuguese: "P"
        case .italian: "I"
        case .dutch: "N"
        case .swedish: "S"
        case .norwegian: "N"
        case .danish: "D"
        case .finnish: "F"
        case .polish: "P"
        case .czech: "Č"
        case .hungarian: "M"
        case .turkish: "T"

        // 日本語
        case .hiragana: "あ"
        case .katakana: "ア"

        // アジア言語
        case .korean: "한"
        case .chineseSimplified: "简"
        case .chineseTraditional: "繁"
        case .thai: "ท"
        case .vietnamese: "V"

        // 中東・その他
        case .arabic: "ع"
        case .hebrew: "ע"

        // ヨーロッパ・その他
        case .russian: "Я"
        case .greek: "Ω"

        // 不明
        case .unknown: "?"
        }
    }
    
    var themeColor: Color {
        switch self {
        // 英数字・ラテン文字系（青系）
        case .abc: .blue
        case .french: Color(red: 0.0, green: 0.3, blue: 0.6)
        case .german: Color(red: 0.1, green: 0.4, blue: 0.7)
        case .spanish: Color(red: 0.8, green: 0.4, blue: 0.0)
        case .portuguese: Color(red: 0.0, green: 0.5, blue: 0.3)
        case .italian: Color(red: 0.0, green: 0.6, blue: 0.4)
        case .dutch: Color(red: 0.9, green: 0.5, blue: 0.0)
        case .swedish: Color(red: 0.0, green: 0.4, blue: 0.7)
        case .norwegian: Color(red: 0.0, green: 0.3, blue: 0.6)
        case .danish: Color(red: 0.8, green: 0.1, blue: 0.2)
        case .finnish: Color(red: 0.0, green: 0.5, blue: 0.8)
        case .polish: Color(red: 0.8, green: 0.1, blue: 0.3)
        case .czech: Color(red: 0.0, green: 0.4, blue: 0.7)
        case .hungarian: Color(red: 0.3, green: 0.7, blue: 0.3)
        case .turkish: Color(red: 0.8, green: 0.0, blue: 0.2)

        // 日本語（赤系）
        case .hiragana: .red
        case .katakana: Color(red: 0.9, green: 0.2, blue: 0.3)

        // アジア言語（緑〜紫系）
        case .korean: Color(red: 0.5, green: 0.0, blue: 0.8)
        case .chineseSimplified: Color(red: 0.8, green: 0.0, blue: 0.0)
        case .chineseTraditional: Color(red: 0.6, green: 0.0, blue: 0.6)
        case .thai: Color(red: 0.2, green: 0.6, blue: 0.8)
        case .vietnamese: Color(red: 0.8, green: 0.6, blue: 0.0)

        // 中東・その他（オレンジ〜茶系）
        case .arabic: Color(red: 0.0, green: 0.6, blue: 0.4)
        case .hebrew: Color(red: 0.0, green: 0.5, blue: 0.7)

        // ヨーロッパ・その他
        case .russian: Color(red: 0.0, green: 0.4, blue: 0.8)
        case .greek: Color(red: 0.2, green: 0.5, blue: 0.9)

        // 不明（グレー）
        case .unknown: .gray
        }
    }
}
