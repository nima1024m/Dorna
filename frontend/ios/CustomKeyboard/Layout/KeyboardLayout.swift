//
//  KeyboardLayout.swift
//  Runner
//
//  Created by Royal Macbook  on 11/5/25.
//
import KeyboardKit
import SwiftUI

/// A layout service that inserts a language switch button left of the space key and removes emoji button.
class LanguageSwitchLayoutService: KeyboardLayout.StandardLayoutService {
    override init(
        baseService: KeyboardLayoutService = KeyboardLayout.DeviceBasedLayoutService(),
        localizedServices: [LocalizedLayoutService] = []
    ) {
        super.init(
            baseService: baseService,
            localizedServices: localizedServices
        )
    }

    override func keyboardLayout(for context: KeyboardContext) -> KeyboardLayout {
        var layout = super.keyboardLayout(for: context)

        let bottomRowIndex = layout.itemRows.count - 1
        guard bottomRowIndex >= 0 else { return layout }
        
        // Create a custom action for language switching
        let languageSwitchAction: KeyboardAction = .custom(named: "languageSwitch")
        let row = layout.itemRows[bottomRowIndex]
        let hasLanguageSwitch = row.contains { $0.action == languageSwitchAction }
        let emojiAction: KeyboardAction = .keyboardType(.emojis)
        let hasEmoji = row.contains { $0.action == emojiAction }
        
        if !hasLanguageSwitch {
            if let spaceItem = layout.firstItem(with: .space) {
                let languageSwitchItem = KeyboardLayout.Item(
                    action: languageSwitchAction,
                    size: .init(width: .points(44), height: spaceItem.size.height),
                    alignment: .center,
                    edgeInsets: spaceItem.edgeInsets
                )
                layout.itemRows.insert(languageSwitchItem, before: .space, inRow: bottomRowIndex)
            }
        }

        // Ensure an emoji button exists next to the space key
        if !hasEmoji {
            if let spaceItem = layout.firstItem(with: .space) {
                let emojiItem = KeyboardLayout.Item(
                    action: emojiAction,
                    size: .init(width: .points(44), height: spaceItem.size.height),
                    alignment: .center,
                    edgeInsets: spaceItem.edgeInsets
                )
                // Insert emoji button before the language switch if present, else before space
                if hasLanguageSwitch {
                    layout.itemRows.insert(emojiItem, before: languageSwitchAction, inRow: bottomRowIndex)
                } else {
                    layout.itemRows.insert(emojiItem, before: .space, inRow: bottomRowIndex)
                }
            }
        }

         // Increase key heights across all rows/items for better tap targets
         let scaledRows: [[KeyboardLayout.Item]] = layout.itemRows.map { row in
             row.map { item in
                 let newSize = KeyboardLayout.ItemSize(
                     width: item.size.width,
                     height: 56.05
                 )
                 

                 var newInsets = item.edgeInsets
                 // Reduce vertical insets to shrink empty vertical space between keys
                 let reducedTop = 0.0
                 let reducedBottom = 11.0
                 newInsets = EdgeInsets(
                     top: reducedTop,
                     leading: newInsets.leading - 1.0,
                     bottom: reducedBottom,
                     trailing: newInsets.trailing+1.3
                 )
                 return KeyboardLayout.Item(
                     action: item.action,
                     size: newSize,
                     alignment: item.alignment,
                     edgeInsets: newInsets
                 )
             }
         }
         layout = KeyboardLayout(
             itemRows: scaledRows,
             inputToolbarInputSet: layout.inputToolbarInputSet
         )

        // Customize bottom row sizes: fixed widths for utility keys, flexible for space
        do {
            var bottomRow = layout.itemRows[bottomRowIndex]
            bottomRow = bottomRow.map { item in
                  let newSize = KeyboardLayout.ItemSize(
                     width: item.size.width,
                     height: 51
                 )

                 var newInsets = item.edgeInsets
                 // Reduce vertical insets to shrink empty vertical space between keys
                let reducedTop = 0.0
                let reducedBottom = 6.0
                 newInsets = EdgeInsets(
                     top: reducedTop,
                     leading: newInsets.leading,
                     bottom: reducedBottom,
                     trailing: newInsets.trailing
                 )
                 return KeyboardLayout.Item(
                     action: item.action,
                     size: newSize,
                     alignment: item.alignment,
                     edgeInsets: newInsets
                 )
            }
            layout.itemRows[bottomRowIndex] = bottomRow
        }
         return layout
     }
}


