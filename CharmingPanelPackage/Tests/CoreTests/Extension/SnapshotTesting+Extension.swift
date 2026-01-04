//
//  SnapshotTesting+Extension.swift
//  CharmingPanelPackage
//
//  Created by kajitani kento on 2026/01/04.
//

import SnapshotTesting
import SwiftUI

@MainActor
public func assertSnapshot<Value: View, Format>(
  of value: @autoclosure () throws -> Value,
  size: CGSize = .init(width: 500, height: 500),
  as snapshotting: Snapshotting<NSView, Format>,
  named name: String? = nil,
  record recording: Bool? = nil,
  timeout: TimeInterval = 5,
  fileID: StaticString = #fileID,
  file filePath: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
  column: UInt = #column
) {
    let nsView = NSHostingView(rootView: try? value())
    nsView.setFrameSize(size)
    
    assertSnapshot(
        of: nsView,
        as: snapshotting,
        named: name,
        record: recording,
        timeout: timeout,
        fileID: fileID,
        file: filePath,
        testName: testName,
        line: line,
        column: column
    )
}
