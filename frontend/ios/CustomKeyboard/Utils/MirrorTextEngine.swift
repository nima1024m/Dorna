//
//  MirrorTextEngine.swift
//  Runner
//
//  Created by Royal Macbook  on 11/22/25.
//
import UIKit
import KeyboardKit
import SwiftUI
import os

/// MirrorTextEngine
/// Maintains a local mirror of the document text and synchronizes it with the UITextDocumentProxy.
/// Uses a robust "Anchor-and-Patch" algorithm to preserve long texts while correcting context drift.
final class MirrorTextEngine {
    
    // MARK: - Public state
    var mirrorText: String = ""
    var cursorPosition: Int = 0 // offset from start of mirrorText
    
    // Config
    private let contextSearchWindow: Int = 30 // characters to use for anchoring
    private let periodicSyncInterval: TimeInterval = 2.0
    
    // Internal
    private var syncTimer: Timer?
    private weak var proxy: UITextDocumentProxy?
    
    init(proxy: UITextDocumentProxy) {
        self.proxy = proxy
        startPeriodicSync()
    }
    
    deinit {
        stopPeriodicSync()
    }
    
    // MARK: - Public API
    
    /// Call this when keyboard receives insertText(_:)
    func handleInsert(text: String) {
        // Optimistic update
        insertTextAtCursor(text)
        
        // Schedule a sync to verify/correct (optional, or rely on periodic)
        // For robustness against "Double Space" shortcuts which change text *after* insert:
        // We should sync shortly after.
        // But for high performance typing, we rely on periodic + context checks.
    }
    
    /// Call this when keyboard receives deleteBackward()
    func handleDeleteBackward() {
        // Optimistic update
        deleteBackwardAtCursor()
    }
    
    /// Call this when keyboard deletes a selection
    func deleteSelection(length: Int) {
        guard length > 0 else { return }
        deleteRangeAtCursor(length: length)
    }
    
    /// Call this when cursor position changes without text modification (e.g., user taps in text)
    /// This is a safer update that only updates the cursor position without modifying the mirrored text
    func handleCursorChange(proxy: UITextDocumentProxy) {
        let before = proxy.documentContextBeforeInput ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        
        // Handle text cleared case - if proxy shows empty, clear the mirror
        if before.isEmpty && after.isEmpty {
            if !mirrorText.isEmpty {
                Logger.debug("MirrorTextEngine: handleCursorChange - text was cleared, resetting mirror")
                mirrorText = ""
                cursorPosition = 0
            }
            return
        }
        
        // If we have no mirrored text yet, initialize from proxy context
        if mirrorText.isEmpty {
            mirrorText = before + after
            cursorPosition = before.count
            return
        }
        
        // Try to find the cursor position based on context matching
        let proxyFullContext = before + after
        
        // Case 1: Exact match
        if mirrorText == proxyFullContext {
            cursorPosition = before.count
            Logger.debug("MirrorTextEngine: handleCursorChange - exact match, cursor at \(cursorPosition)")
            return
        }
        
        // Case 2: Our mirror is longer (proxy may be truncating)
        if mirrorText.count > proxyFullContext.count {
            // Try to find the cursor position by matching context
            if let matchedPos = findBestCursorPosition(before: before, after: after) {
                cursorPosition = matchedPos
                Logger.debug("MirrorTextEngine: handleCursorChange - found cursor at \(cursorPosition) via context matching")
                return
            }
            
            // Fallback: If 'before' content appears to match a prefix range of mirrorText
            if !before.isEmpty {
                // Check if before matches the end portion up to that length
                let potentialPos = before.count
                if potentialPos <= mirrorText.count {
                    let mirrorPrefix = String(mirrorText.prefix(potentialPos))
                    // Check suffix match (the visible part should match)
                    let minLen = min(30, before.count, mirrorPrefix.count)
                    let beforeSuffix = String(before.suffix(minLen))
                    let mirrorSuffix = String(mirrorPrefix.suffix(minLen))
                    
                    if beforeSuffix == mirrorSuffix {
                        cursorPosition = potentialPos
                        Logger.debug("MirrorTextEngine: handleCursorChange - cursor at \(cursorPosition) via prefix match")
                        return
                    }
                }
            }
        }
        
        // Case 3: Proxy context is larger (text was added externally - paste, undo, etc.)
        // In this case, do a full sync to update both text and cursor
        syncWithContext(before: before, after: after)
    }

    /// Manual sync call
    func performImmediateSync() {
        guard let proxy = proxy else { return }
        // Fetch context safely
        let before = proxy.documentContextBeforeInput ?? ""
        let after = proxy.documentContextAfterInput ?? ""
        
        syncWithContext(before: before, after: after)
    }
    
    /// Set full text (e.g. from a full scrape)
    func setFullText(_ text: String, cursorAt position: Int) {
        mirrorText = text
        cursorPosition = max(0, min(position, text.count))
    }
    
    func stopPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = nil
    }
    
    // MARK: - Private Core Logic
    
    private func insertTextAtCursor(_ text: String) {
        let safeIndex = min(max(0, cursorPosition), mirrorText.count)
        let index = mirrorText.index(mirrorText.startIndex, offsetBy: safeIndex)
        mirrorText.insert(contentsOf: text, at: index)
        cursorPosition += text.count
    }
    
    private func deleteBackwardAtCursor() {
        guard cursorPosition > 0, !mirrorText.isEmpty else {
            // Nothing to delete or unknown state, force sync
            performImmediateSync()
            return
        }
        let safeIndex = min(cursorPosition, mirrorText.count)
        let removeIndex = mirrorText.index(mirrorText.startIndex, offsetBy: safeIndex - 1)
        mirrorText.remove(at: removeIndex)
        cursorPosition -= 1
    }
    
    private func deleteRangeAtCursor(length: Int) {
        let safeStart = min(max(0, cursorPosition), mirrorText.count)
        let safeEnd = min(safeStart + length, mirrorText.count)
        guard safeEnd > safeStart else { return }
        
        let startIndex = mirrorText.index(mirrorText.startIndex, offsetBy: safeStart)
        let endIndex = mirrorText.index(mirrorText.startIndex, offsetBy: safeEnd)
        
        mirrorText.removeSubrange(startIndex..<endIndex)
        // Cursor stays at start of deletion
    }
    
    // MARK: - Anchor-and-Patch Algorithm
    
    private func syncWithContext(before: String, after: String) {
        // Handle empty case - don't wipe mirror if we have significant data
        if before.isEmpty && after.isEmpty {
            // If document is truly empty, reset mirror
                mirrorText = ""
                cursorPosition = 0
            // Otherwise keep existing mirror data
            return
        }
        
        // CURSOR-ONLY SYNC DETECTION:
        // If the proxy's before+after context matches what's in mirrorText,
        // this is likely just a cursor position change, not a text change.
        // In this case, we only update the cursor position.
        let proxyFullContext = before + after
        
        // Check if this is purely a cursor move within existing text
        if !mirrorText.isEmpty {
            // For cursor-only moves: the proxy context should be a substring of our mirror
            // or the mirror should contain the proxy context
            if mirrorText == proxyFullContext {
                // Perfect match - just update cursor to before.count
                cursorPosition = before.count
                return
            }
            
            // Check if proxy context is a truncated version of our mirror
            // iOS often truncates context for long documents
            if mirrorText.count > proxyFullContext.count {
                // Verify the proxy context matches what we expect at that cursor position
                let expectedBefore = String(mirrorText.prefix(before.count))
                let potentialCursorPos = before.count
                
                if potentialCursorPos <= mirrorText.count {
                    // Check if 'before' matches the prefix of mirrorText up to that position
                    let mirrorPrefix = String(mirrorText.prefix(potentialCursorPos))
                    
                    // If 'before' matches the end of mirrorPrefix (accounting for truncation)
                    if mirrorPrefix.hasSuffix(before) || before.isEmpty || mirrorPrefix == before {
                        // Check 'after' matches what follows in mirrorText
                        let mirrorSuffix = String(mirrorText.suffix(from: mirrorText.index(mirrorText.startIndex, offsetBy: potentialCursorPos)))
                        
                        if mirrorSuffix.hasPrefix(after) || after.isEmpty || mirrorSuffix == after {
                            // Context matches at this position - just update cursor
                            cursorPosition = potentialCursorPos
                            Logger.debug("MirrorTextEngine: Cursor-only sync - cursor moved to \(cursorPosition)")
                            return
                        }
                    }
                }
                
                // Try to find the best cursor position by matching the context
                if let matchedPos = findBestCursorPosition(before: before, after: after) {
                    cursorPosition = matchedPos
                    Logger.debug("MirrorTextEngine: Found cursor position via context matching: \(cursorPosition)")
                    return
                }
            }
        }
        
        // 1. Anchor Left
        // Find the longest prefix of `before` that exists in `mirrorText` ending near the cursor.
        // If `before` is short (Start of Doc), we require it to anchor at the start.
        
        let isStartOfDoc = before.count < contextSearchWindow
        
        // We look for a match of `before` (or its prefix) in `mirrorText`.
        // We search backwards from `estimatedIndex`.
        let estimatedIndex = min(max(0, cursorPosition), mirrorText.count)
        
        let (leftAnchorIndex, matchedBeforeLength) = findLeftAnchor(
            before: before,
            in: mirrorText,
            around: estimatedIndex,
            isStartOfDoc: isStartOfDoc
        )
        
        // `leftAnchorIndex` is the index in `mirrorText` where the matched part ENDS.
        // `matchedBeforeLength` is the length of `before` that matched.
        
        // Everything up to `leftAnchorIndex` in `mirrorText` is considered "Valid History" (matched).
        // EXCEPT if `isStartOfDoc` and we had to skip some junk at the start.
        // The `findLeftAnchor` handles the search.
        // If there is "Junk" at the start (StartOfDoc but match > 0), we need to include that junk in the "Gap" to be replaced.
        // So `gapStart` should be 0 if `isStartOfDoc`.
        // Otherwise `gapStart` is `leftAnchorIndex`.
        
        var gapStart = leftAnchorIndex
        if isStartOfDoc {
            // If we are at start of doc, the valid text STARTS at the match.
            // Anything before the match is junk.
            // So the Gap starts at 0.
            gapStart = 0
            
            // NOTE: If we set gapStart to 0, we must ensure that the `matchedBeforeLength` logic
            // correctly accounts for the fact that we are keeping the matched part?
            // "Anchor-and-Patch" replaces [GapStart ..< GapEnd] with [MissingBefore + MissingAfter??]
            // Actually:
            // Target Text = `before` + `after`.
            // We matched `before.prefix(matchedBeforeLength)`.
            // This matched part is at `mirrorText[...leftAnchorIndex]`.
            // If we keep it, we don't put it in the replacement.
            // So we replace `Gap` with `before.suffix(from: matchedBeforeLength)`.
            
            // If StartOfDoc, and `leftAnchorIndex` > 0.
            // Then `mirrorText[0..<leftAnchorIndex]` matched the prefix.
            // Wait, if it *matches*, it's not junk.
            // Junk is `mirrorText[0..<matchStart]`.
            // `findLeftAnchor` returns the END of the match.
            // So if match length is 5, and it ends at 7. Match is 2..<7. Junk is 0..<2.
            // We need to know the Match Start.
            // `matchStart = leftAnchorIndex - matchedBeforeLength`.
            // If `isStartOfDoc` and `matchStart > 0`, then 0..<matchStart is Junk.
            // We should remove it.
            // So `gapStart` should be `matchStart`? No, we want to replace the junk.
            // So `gapStart` = 0.
            // And we need to replace 0..<matchEnd?
            // No, we want to Keep the match.
            // So we delete 0..<matchStart.
        }
        
        // Let's refine the Patching logic based on ranges.
        let matchEnd = leftAnchorIndex
        let matchStart = matchEnd - matchedBeforeLength
        
        // Determine the range in `mirrorText` to "Keep" (The Left Anchor)
        // If StartOfDoc, we keep `matchStart..<matchEnd`. We delete `0..<matchStart`.
        // If Not StartOfDoc, we keep `0..<matchEnd`.
        
        var replaceStart = matchEnd
        if isStartOfDoc && matchStart > 0 {
            // Example "HHello", before="Hello". Match "Hello" at 1..6.
            // MatchStart=1.
            // We want to delete 0..1.
            // So the "Gap" effectively starts at 0?
            // And we want to put "Hello" there?
            // No, "Hello" is already at 1..6.
            // We just want to remove 0..1.
            // So we delete 0..matchStart.
            // Let's handle this "Start Cleanup" separately before evaluating the Gap to Right Anchor.
            
            let startIdx = mirrorText.startIndex
            let junkEndIdx = mirrorText.index(startIdx, offsetBy: matchStart)
            mirrorText.removeSubrange(startIdx..<junkEndIdx)
            // Adjust indices
            let deletedCount = matchStart
            // cursorPosition -= deletedCount // Logic will auto-set cursor later
            // leftAnchorIndex -= deletedCount
            replaceStart -= deletedCount
            
            Logger.debug("MirrorTextEngine: Trimmed \(deletedCount) junk chars from start.")
        } else if isStartOfDoc && matchStart == 0 {
            // Perfect alignment at start.
            // Keep 0..matchEnd.
            replaceStart = matchEnd
        } else {
            // Not start of doc. Keep history 0..matchEnd.
            replaceStart = matchEnd
        }
        
        // 2. Anchor Right
        // Find `after` in `mirrorText` starting from `replaceStart`.
        // `after` might be empty (End of doc).
        
        let (rightAnchorIndex, _) = findRightAnchor(
            after: after,
            in: mirrorText,
            searchFrom: replaceStart
        )
        
        // `rightAnchorIndex` is the index in `mirrorText` where the valid `after` context STARTS.
        // Everything from `rightAnchorIndex...` is valid history (or valid future).
        
        // 3. Patch
        // The Gap is `replaceStart ..< rightAnchorIndex`.
        // The Content to Fill is `before.suffix(from: matchedBeforeLength)`.
        
        let gapRange = replaceStart..<rightAnchorIndex
        let remainingBeforeCount = before.count - matchedBeforeLength
        let contentToInsert = String(before.suffix(remainingBeforeCount))
        
        // Verify if update is needed
        // If Gap is empty and Content is empty, we are synced.
        if gapRange.isEmpty && contentToInsert.isEmpty {
            // No changes needed text-wise.
            // Just update cursor.
        } else {
            // Perform replacement
            let startIdx = mirrorText.index(mirrorText.startIndex, offsetBy: gapRange.lowerBound)
            let endIdx = mirrorText.index(mirrorText.startIndex, offsetBy: gapRange.upperBound)
            
            // Check if what we are replacing is actually different (avoid churn)
            let currentContent = String(mirrorText[startIdx..<endIdx])
            if currentContent != contentToInsert {
                mirrorText.replaceSubrange(startIdx..<endIdx, with: contentToInsert)
                Logger.debug("MirrorTextEngine: Patched range \(gapRange.lowerBound)..<\(gapRange.upperBound) ('\(currentContent)') with '\(contentToInsert)'")
            }
        }
        
        // 4. Update Cursor
        // Cursor should be at the end of the `before` insertion.
        // which is `replaceStart + contentToInsert.count`.
        cursorPosition = replaceStart + contentToInsert.count

        // IMPORTANT FIX: Only update mirrorText from proxy context if mirrorText is empty or very small
        // This prevents overwriting long text with truncated proxy context during cursor moves
        if mirrorText.isEmpty && !proxyFullContext.isEmpty {
            mirrorText = proxyFullContext
            cursorPosition = before.count
        }
    }
    
    /// Find the best cursor position by matching before/after context within mirrorText
    private func findBestCursorPosition(before: String, after: String) -> Int? {
        guard !mirrorText.isEmpty else { return nil }
        
        // Strategy: Find where 'before' ends and 'after' starts in mirrorText
        // For short context strings, match exactly
        // For longer ones, use suffix/prefix matching
        
        let searchLen = min(20, before.count)
        guard searchLen > 0 else {
            // Empty before - cursor should be at start if after matches start
            if after.isEmpty || mirrorText.hasPrefix(after) {
                return 0
            }
            return nil
        }
        
        // Get the suffix of 'before' to search for
        let searchSuffix = String(before.suffix(searchLen))
        
        // Search for this suffix in mirrorText
        if let range = mirrorText.range(of: searchSuffix, options: .backwards) {
            let potentialPos = mirrorText.distance(from: mirrorText.startIndex, to: range.upperBound)
            
            // Validate with 'after' context if available
            if !after.isEmpty && potentialPos < mirrorText.count {
                let mirrorAfter = String(mirrorText.suffix(from: mirrorText.index(mirrorText.startIndex, offsetBy: potentialPos)))
                let afterPrefix = String(after.prefix(min(10, after.count)))
                if mirrorAfter.hasPrefix(afterPrefix) {
                    return potentialPos
                }
            } else {
                return potentialPos
            }
        }
        
        return nil
    }
    
    // MARK: - Helpers
    
    // Returns (EndIndex match in mirror, Length of matched before suffix)
    private func findLeftAnchor(before: String, in text: String, around centerIndex: Int, isStartOfDoc: Bool) -> (Int, Int) {
        let textCount = text.count
        if before.isEmpty { return (centerIndex, 0) } // No anchor, assume cursor is anchor
        
        // We want to find the Longest possible Prefix of `before` that exists in `text`.
        // Optimally, it should be the whole `before`.
        // We search backwards from `centerIndex` (expected location).
        
        // Optimization: Check exact match of full `before` first
        if let range = text.range(of: before, options: .backwards, range: rangeAround(centerIndex, in: text)) {
            let endIndex = text.distance(from: text.startIndex, to: range.upperBound)
            return (endIndex, before.count)
        }
        
        // Fallback: Check prefixes of `before` (decreasing length)
        // Only if we suspect the `before` text contains new changes not in mirror.
        // We limit how far back we check prefixes to keep performance.
        let minPrefixToCheck = 1
        var bestMatchLen = 0
        var bestMatchEnd = isStartOfDoc ? 0 : centerIndex // Default if no match found
        
        // If StartOfDoc, we prioritize matches that start at 0.
        // Actually, if StartOfDoc, we verify if `text` starts with `before` prefix.
        if isStartOfDoc {
             // Check common prefix
             let common = text.commonPrefix(with: before)
             if !common.isEmpty {
                 return (common.count, common.count)
             }
             // If no common prefix at 0, maybe "Junk" case.
             // We can search for `before` in the first N chars.
             if let range = text.range(of: before) {
                 // Found full match elsewhere
                 let end = text.distance(from: text.startIndex, to: range.upperBound)
                 return (end, before.count)
             }
        }
        
        // General search for longest prefix
        // We iterate prefixes from large to small
        let step = 4 // optimization step
        for len in stride(from: before.count, to: minPrefixToCheck, by: -step) {
            let prefix = String(before.prefix(len))
            // Search window: we expect the match to End near centerIndex.
            // So we search in `..<centerIndex`.
             if let range = text.range(of: prefix, options: .backwards, range: rangeAround(centerIndex, in: text)) {
                 let end = text.distance(from: text.startIndex, to: range.upperBound)
                 return (end, len)
             }
        }
        
        // If no reasonable prefix match found, we assume:
        // 1. The text completely changed.
        // 2. Or we are lost.
        // Return 0 match length, and anchor to... centerIndex?
        // If we matched nothing, `matchedBeforeLength` = 0.
        // `gapStart` = `centerIndex`.
        // ContentToInsert = `before` (Full).
        // This effectively inserts `before` at `centerIndex`.
        return (centerIndex, 0)
    }
    
    // Returns (StartIndex match in mirror, Length matched - optional)
    private func findRightAnchor(after: String, in text: String, searchFrom: Int) -> (Int, Int) {
        if after.isEmpty {
            // Empty after context -> Matches End of Text.
            // Wait, does it? Or does it match any empty gap?
            // "Ghost text" removal relies on matching End of Text.
            // If `after` is empty, we return text.count
            return (text.count, 0)
        }
        
        let startIdx = text.index(text.startIndex, offsetBy: min(searchFrom, text.count))
        let searchRange = startIdx..<text.endIndex
        
        // We want to find a Prefix of `after` in `text`?
        // Actually we want the Start of `after`.
        // So we search for `after`.
        
        if let range = text.range(of: after, options: [], range: searchRange) {
             let start = text.distance(from: text.startIndex, to: range.lowerBound)
             return (start, after.count)
        }
        
        // Fallback: matching prefix of `after`?
        // If `after` was truncated by proxy, we assume we have the start of it.
        // If user typed inside `after` (e.g. forward delete?), `after` changes.
        // But usually `after` is stable.
        
        // If exact match fail, maybe we are near End of Doc?
        // Check if `text` ends with a prefix of `after`?
        // No, `after` STARTS with...
        // Check if `text` has `after.prefix(N)`?
         for len in stride(from: after.count - 1, to: 4, by: -4) {
             let prefix = String(after.prefix(len))
             if let range = text.range(of: prefix, options: [], range: searchRange) {
                 let start = text.distance(from: text.startIndex, to: range.lowerBound)
                 return (start, len)
             }
         }
        
        // If no match, we assume `after` is new/not found.
        // We push the anchor to the End.
        // Replaces everything until End.
        return (text.count, 0)
    }
    
    private func rangeAround(_ center: Int, in text: String) -> Range<String.Index> {
        let span = 300 // Look behind/ahead
        let start = max(0, center - span)
        let end = min(text.count, center + span)
        let startIdx = text.index(text.startIndex, offsetBy: start)
        let endIdx = text.index(text.startIndex, offsetBy: end)
        return startIdx..<endIdx
    }
    
    private func startPeriodicSync() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.syncTimer = Timer.scheduledTimer(withTimeInterval: self.periodicSyncInterval, repeats: true, block: { [weak self] _ in
                self?.performImmediateSync()
            })
        }
    }
}
