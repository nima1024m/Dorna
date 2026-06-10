//
//  PersianLayoutService.swift
//  Runner
//
//  Created by Royal Macbook  on 11/5/25.
//
import KeyboardKit
import SwiftUI

// Add a custom layout service for Persian that filters out shift keys
class PersianLayoutService: KeyboardLayout.DeviceBasedLayoutService {
    override func keyboardLayout(for context: KeyboardContext) -> KeyboardLayout {
        let defaultLayout = super.keyboardLayout(for: context)
        let filteredRows = defaultLayout.itemRows.map { row in
            row.filter { item in
                if case .shift = item.action { return false }
                return true
            }
        }
        // Insert half-space after space in bottom row
        let modifiedRows = filteredRows.enumerated().map { index, rowItems in
            if index == filteredRows.count - 1 {
                var newRow: [KeyboardLayout.Item] = []
                for item in rowItems {
                    newRow.append(item)
                    if item.action == .space {
                        let halfSpaceItem = KeyboardLayout.Item(
                            action: .character(String.zeroWidthSpace),
                            size: .init(width: .points(40), height: item.size.height),
                            alignment: item.alignment,
                            edgeInsets: item.edgeInsets
                        )
                        newRow.append(halfSpaceItem)
                    }
                }
                return newRow
            }
            return rowItems
        }
        // Adjustments specific to Persian layout:
        // 1) Make backspace key the same width as normal keys.
        // 2) Remove horizontal padding on the first and second rows.
        let adjustedRows: [[KeyboardLayout.Item]] = modifiedRows.enumerated().map { rowIndex, rowItems in
            // Map each item and apply row-specific changes
            return rowItems.enumerated().map { itemIndex, item in
                var result = item

                // 1) Backspace width: use standard input width
                if case .backspace = item.action {
                    result = KeyboardLayout.Item(
                        action: item.action,
                        size: .init(width: .input, height: item.size.height),
                        alignment: item.alignment,
                        edgeInsets: item.edgeInsets
                    )
                }

                // 2) Only remove outer horizontal padding for first and last buttons on rows 0 and 1
                if rowIndex == 0 || rowIndex == 1 {
                    let insets = result.edgeInsets
                    var leading = insets.leading
                    var trailing = insets.trailing
                    if itemIndex == 0 {
                    leading = insets.leading
                     }
                    if itemIndex == rowItems.count - 1 {
                    trailing = insets.trailing
                     }
                    let adjustedInsets = EdgeInsets(top: insets.top, leading: leading, bottom: insets.bottom, trailing: trailing)
                    result = KeyboardLayout.Item(
                        action: result.action,
                        size: result.size,
                        alignment: result.alignment,
                        edgeInsets: adjustedInsets
                    )
                }

                return result
            }
        }

        return KeyboardLayout(
            itemRows: adjustedRows,
            inputToolbarInputSet: defaultLayout.inputToolbarInputSet
        )
    }
}

