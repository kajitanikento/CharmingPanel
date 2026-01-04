//
//  ActorPanelViewTests.swift
//  CoreTests
//
//  Created by Claude on 2026/01/04.
//

import Testing
import SwiftUI
import SnapshotTesting
import ComposableArchitecture
@testable import Core

@MainActor
final class ActorPanelViewTests {

    // MARK: - 基本的なビューテスト

    @Test
    func testActorPanelView_withDefaultState() {
        let store = Store(initialState: ActorPanel.State()) {
            ActorPanel()
        } withDependencies: {
            $0.inputSource.stream = { .init { continuation in
                continuation.yield(.abc)
            } }
        }

        let view = ActorPanelView(store: store)
            .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)
        
        assertSnapshot(of: view, as: .image)
    }

    @Test
    func testActorPanelView_withHiraganaInputSource() {
        let store = Store(initialState: ActorPanel.State(currentInputSource: .hiragana)) {
            ActorPanel()
        } withDependencies: {
            $0.inputSource.stream = { .init { continuation in
                continuation.yield(.hiragana)
            } }
        }

        let view = ActorPanelView(store: store)
            .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func testActorPanelView_withKatakanaInputSource() {
        let store = Store(initialState: ActorPanel.State(currentInputSource: .katakana)) {
            ActorPanel()
        } withDependencies: {
            $0.inputSource.stream = { .init { continuation in
                continuation.yield(.katakana)
            } }
        }

        let view = ActorPanelView(store: store)
            .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func testActorPanelView_withKoreanInputSource() {
        let store = Store(initialState: ActorPanel.State(currentInputSource: .korean)) {
            ActorPanel()
        } withDependencies: {
            $0.inputSource.stream = { .init { continuation in
                continuation.yield(.korean)
            } }
        }

        let view = ActorPanelView(store: store)
            .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func testActorPanelView_withChineseSimplifiedInputSource() {
        let store = Store(initialState: ActorPanel.State(currentInputSource: .chineseSimplified)) {
            ActorPanel()
        } withDependencies: {
            $0.inputSource.stream = { .init { continuation in
                continuation.yield(.chineseSimplified)
            } }
        }

        let view = ActorPanelView(store: store)
            .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

        assertSnapshot(of: view, as: .image)
    }

    // MARK: - 猫のタイプ別テスト

    @Test
    func testActorPanelView_withThinkCatType() {
        var state = ActorPanel.State()
        state.cat.type = .think
        state.isShowMenu = true

        let store = Store(initialState: state) {
            ActorPanel()
        } withDependencies: {
            $0.inputSource.stream = { .init { continuation in
                continuation.yield(.abc)
            } }
        }

        let view = ActorPanelView(store: store)
            .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func testActorPanelView_withPickUpCatType() {
        var state = ActorPanel.State()
        state.cat.type = .pickUp
        state.isLongPress = true

        let store = Store(initialState: state) {
            ActorPanel()
        } withDependencies: {
            $0.inputSource.stream = { .init { continuation in
                continuation.yield(.abc)
            } }
        }

        let view = ActorPanelView(store: store)
            .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func testActorPanelView_withHasTimerCatType() {
        var state = ActorPanel.State()
        state.cat.type = .hasTimer
        state.pomodoroTimer.time = .init(startDate: .now, intervalMinute: 25)

        let store = Store(initialState: state) {
            ActorPanel()
        } withDependencies: {
            $0.inputSource.stream = { .init { continuation in
                continuation.yield(.abc)
            } }
        }

        let view = ActorPanelView(store: store)
            .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

        assertSnapshot(of: view, as: .image)
    }

    @Test
    func testActorPanelView_withCompleteTimerCatType() {
        var state = ActorPanel.State()
        state.cat.type = .completeTimer
        state.pomodoroTimer.isComplete = true
        state.pomodoroTimer.time = .init(startDate: .now, intervalMinute: 25)

        let store = Store(initialState: state) {
            ActorPanel()
        } withDependencies: {
            $0.inputSource.stream = { .init { continuation in
                continuation.yield(.abc)
            } }
        }

        let view = ActorPanelView(store: store)
            .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

        assertSnapshot(of: view, as: .image)
    }

    // MARK: - 複数言語の入力ソーステスト

    @Test
    func testActorPanelView_withVariousEuropeanInputSources() {
        let inputSources: [InputSource] = [.french, .german, .spanish, .italian, .russian]

        for inputSource in inputSources {
            let store = Store(initialState: ActorPanel.State(currentInputSource: inputSource)) {
                ActorPanel()
            } withDependencies: {
                $0.inputSource.stream = { .init { continuation in
                    continuation.yield(inputSource)
                } }
            }

            let view = ActorPanelView(store: store)
                .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

            assertSnapshot(
                of: view,
                as: .image,
                named: "with\(String(describing: inputSource).capitalized)"
            )
        }
    }

    @Test
    func testActorPanelView_withVariousAsianInputSources() {
        let inputSources: [InputSource] = [.thai, .vietnamese, .arabic, .hebrew]

        for inputSource in inputSources {
            let store = Store(initialState: ActorPanel.State(currentInputSource: inputSource)) {
                ActorPanel()
            } withDependencies: {
                $0.inputSource.stream = { .init { continuation in
                    continuation.yield(inputSource)
                } }
            }

            let view = ActorPanelView(store: store)
                .frame(width: ActorPanelView.size.width, height: ActorPanelView.size.height)

            assertSnapshot(
                of: view,
                as: .image,
                named: "with\(String(describing: inputSource).capitalized)"
            )
        }
    }
}
