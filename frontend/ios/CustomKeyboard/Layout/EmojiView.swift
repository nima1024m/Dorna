//
//  EmojiView.swift
//  Runner
//
//  Created by Royal Macbook  on 11/5/25.
//

import SwiftUI
import KeyboardKit

// Complete emoji view used by the emoji keyboard
public struct CompleteEmojiView: View {
    public let actionHandler: KeyboardActionHandler
    public let isDarkMode: Bool
    public let onClose: () -> Void
    @State private var selectedCategory: EmojiCategory = .persisted(.recent)

    private var categories: [EmojiCategory] {
        var cats: [EmojiCategory] = [.persisted(.recent)]
        cats.append(contentsOf: EmojiCategory.standardCategories)
        return cats
    }

    private var allStandardEmojis: [Emoji] {
        EmojiCategory.standardCategories.flatMap { $0.emojis }
    }

    private let defaultRecentChars: [String] = [
        "😂", "❤️", "🤣", "👍", "😭", "😍", "😊", "🙏", "😘", "🥰",
        "😅", "😍", "😏", "🤔", "😎", "😩", "😭", "🤤", "🥺",
        "😭", "✨", "😌", "😡", "🥹", "🤗", "😤", "😉", "🤨", "🤯",
        "🤮", "😷", "🤒", "🤧", "✌️", "🙌", "👀", "🤝", "💯", "🔥",
        "🌚", "😳", "😱", "💔", "😜", "😝", "😛", "🙂", "😐", "😑",
        "😉", "🤨", "😇", "🙂"
    ]

    private func defaultRecentEmojis() -> [Emoji] {
        var map: [String: Emoji] = [:]
        for e in allStandardEmojis { map[e.char] = e }
        var seen: Set<String> = []
        var result: [Emoji] = []
        for ch in defaultRecentChars {
            if !seen.contains(ch) {
                seen.insert(ch)
                if let e = map[ch] { result.append(e) }
            }
        }
        return result
    }

    private func emojisForCategory(_ category: EmojiCategory) -> [Emoji] {
        // If this is the recent category, prepend persisted recents and fill
        // with defaults (first standard category), excluding duplicates.
        if category.id == EmojiCategory.persisted(.recent).id {
            let recents = EmojiCategory.Persisted.recent.getEmojis()
            let defaults = defaultRecentEmojis()
            let recentChars = Set(recents.map { $0.char })
            let filteredDefaults = defaults.filter { !recentChars.contains($0.char) }
            return Array((recents + filteredDefaults).prefix(32))
        }
        return category.emojis
    }

    private let columns = Array(repeating: GridItem(.flexible()), count: 8)

    public var body: some View {
        VStack(spacing: 0) {
                TabView(selection: $selectedCategory) {
                    ForEach(categories, id: \.id) { category in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(rows: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                                ForEach(emojisForCategory(category), id: \.id) { emoji in
                                    Button(action: {
                                        actionHandler.handle(.emoji(emoji))
                                        EmojiCategory.Persisted.recent.addEmoji(emoji)
                                    }) {
                                        Text(emoji.char)
                                            .font(.system(size: 28))
                                            .frame(width: 40, height: 40)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        }
                        .background(AppColors.Background.keyboard(isDarkMode: isDarkMode))
                        .tag(category)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

            
            Divider()
            HStack(spacing: 0) {
                Button(action: {
                    actionHandler.handle(.keyboardType(.alphabetic))
                    onClose()
                }) {
                    Text("ABC")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                        .padding(8)
                }
                .frame(width: 44)

                ForEach(categories, id: \.id) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        category.symbolIcon
                            .resizable()
                            .scaledToFit()
                            .frame(width: 16, height: 16)
                            .foregroundColor(category == selectedCategory ? .blue : .primary)
                            .padding(6)
                    }
                    .frame(maxWidth: .infinity)
                }

                Button(action: {
                    actionHandler.handle(.backspace)
                }) {
                    Image(systemName: "delete.left")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.primary)
                        .padding(8)
                }
                .frame(width: 44)
            }
            .background(Color(.systemGray5))
        }
    }
}
