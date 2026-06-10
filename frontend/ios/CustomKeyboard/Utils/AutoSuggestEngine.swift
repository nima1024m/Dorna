//
//  AutoSuggestEngine.swift
//  CustomKeyboard

import Foundation
import UIKit

final class AutoSuggestEngine {
    /// Temporary flag to enable/disable Persian auto-suggestions.
    static var isPersianEnabled: Bool = false

    private let languageIdentifier: String
    private let checker = UITextChecker()

    // MARK: - N-gram stores (English)
    /// Unigram frequencies: word -> frequency
    private var unigramEN: [String: Int] = [:]
    private var maxUnigramEN: Int = 0
    /// Ordered top unigrams by frequency (first entries are most frequent)
    private var unigramTopEN: [String] = []
    private let unigramCapEN: Int = 100_000
    /// Next-word maps built from n-grams: context -> [(nextWord, freq)]
    private var bigramNextEN: [String: [(String, Int)]] = [:]   // last1 -> next
    private var trigramNextEN: [String: [(String, Int)]] = [:]  // last2 -> next
    private var fourgramNextEN: [String: [(String, Int)]] = [:] // last3 -> next

    // MARK: - Unigram store (Persian)
    private var unigramFA: [String: Int] = [:]
    private var maxUnigramFA: Int = 0
    private var unigramTopFA: [String] = []
    private let unigramCapFA: Int = 100_000

    // Load guards to ensure per-language assets are loaded only once
    private var didLoadEN: Bool = false
    private var didLoadFA: Bool = false
    
    // MARK: - Progressive Loading
    /// Thread-safe access queue for dictionary reads/writes
    private let accessQueue = DispatchQueue(label: "com.dorna.autosuggest.access", attributes: .concurrent)
    /// Background queue for progressive loading
    private let loadQueue = DispatchQueue(label: "com.dorna.autosuggest.load", qos: .utility)
    /// Scheduled work items for cancellation on deinit
    private var loadWorkItems: [DispatchWorkItem] = []
    /// Flag to indicate if engine is being deallocated
    private var isInvalidated: Bool = false
    
    /// Progressive loading phases with limits
    private enum LoadPhase: Int, CaseIterable {
        case initial = 0    // ~1,000 entries - immediate
        case fast = 1       // ~5,000 entries - after 0.5s
        case medium = 2     // ~20,000 entries - after 2s
        case complete = 3   // all entries - after 5s
        
        var unigramLimit: Int {
            switch self {
            case .initial: return 1_000
            case .fast: return 5_000
            case .medium: return 20_000
            case .complete: return 100_000
            }
        }
        
        var ngramLineLimit: Int {
            switch self {
            case .initial: return 0         // No n-grams initially
            case .fast: return 5_000        // Basic bigrams
            case .medium: return 20_000     // More bigrams + trigrams
            case .complete: return Int.max  // All n-grams
            }
        }
        
        var delay: TimeInterval {
            switch self {
            case .initial: return 0
            case .fast: return 0.5
            case .medium: return 2.0
            case .complete: return 5.0
            }
        }
    }
    
    /// Current loading phase
    private var currentPhaseEN: LoadPhase = .initial
    private var currentPhaseFA: LoadPhase = .initial
    
    /// Cached file content to avoid re-reading
    private var cachedUnigramENContent: String?
    private var cachedUnigramFAContent: String?
    private var cachedBigramContent: String?
    private var cachedTrigramContent: String?
    private var cachedFourgramContent: String?

    /// Special-case corrections (mainly contractions)
    private let contractions: [String: String] = [
        "dont": "don't",
        "doesnt": "doesn't",
        "didnt": "didn't",
        "cant": "can't",
        "wont": "won't",
        "shouldnt": "shouldn't",
        "couldnt": "couldn't",
        "wouldnt": "wouldn't",
        "isnt": "isn't",
        "arent": "aren't",
        "ive": "I've",
        "im": "I'm",
        "lets": "let's",
        "youre": "you're",
        "theyre": "they're",
        "weve": "we've",
        "hes": "he's",
        "shes": "she's",
        "itll": "it'll",
        "ill": "I'll",
        "youll": "you'll",
        "theyll": "they'll",
    ]

    private let sentenceStartEN: [String] = ["I", "We", "You", "It", "The", "Thanks", "Hello", "Hi"]

    // Local English bigrams (checked before file-based maps)
    // Keys are lowercased; values are candidate next tokens ordered by preference.
    private let bigramENLocal: [String: [String]] = [
        "i": ["am", "have", "think", "want", "need", "will"],
        "you": ["are", "have", "can", "will", "need"],
        "he": ["is", "has", "will"],
        "she": ["is", "has", "will"],
        "we": ["are", "have", "can", "will"],
        "they": ["are", "have", "will"],
        "thank": ["you"],
        "thanks": ["for", "so", "a"],
        "good": ["morning", "night", "luck", "job"],
        "happy": ["birthday", "to"],
        "let": ["me", "us"],
        "how": ["are", "is", "do"],
        "see": ["you", "you soon"],
        "on": ["the", "my", "your"],
        "at": ["the", "home", "work", "school"],
        "for": ["you", "me", "the", "now"],
        "to": ["you","the", "be", "do"],
        "in": ["the", "my", "your"],
        "with": ["you", "me", "the"],
        "hello": ["how", "I", "there", ],
        "hi": ["there"],
        "it": ["is", "was", "will"],
        "this": ["is", "was"],
        "that": ["is", "was"],
    ]

    // Minimal Persian phrases for meaningful next-word suggestions
    private let bigramFA: [String: [String]] = [
        "سلام": ["خوبی؟", "وقت‌بخیر", "چطوری؟"],
        "روز": ["بخیر", "خوش"],
        "وقت": ["بخیر"],
        "متشکرم": ["از", "خیلی"],
        "خواهش": ["می‌کنم"],
        "لطفاً": ["بگویید", "کمک", "صبر"],
        "من": ["هستم", "می‌خواهم", "دارم", "می‌توانم", "باید", "می‌روم", "رفتم"],
        "تو": ["هستی", "می‌خواهی", "می‌توانی", "باید", "داری"],
        "او": ["می‌خواهد", "داشت", "رفت"],
        "ما": ["هستیم", "می‌خواهیم", "می‌توانیم", "باید", "داریم"],
        "شما": ["هستید", "می‌خواهید", "می‌توانید", "باید", "دارید"],
        "آن": ["را", "ها", "که"],
        "این": ["را", "ها", "که"],
        "به": ["نظر", "زودی", "خاطر", "دلیل", "همراه", "سمت"],
        "از": ["شما", "این", "آن", "طرف", "قبل", "بعد"],
        "برای": ["شما", "این", "آن", "همه"],
        "در": ["مورد", "خانه", "مدرسه", "محل"],
        "با": ["شما", "هم", "من"],
        "که": ["من", "تو", "او", "ما", "شما"],
        "چطور": ["هستی؟", "هستید؟"],
        "امروز": ["صبح", "عصر", "شب"],
        "دیروز": ["صبح", "عصر", "شب"],
    ]
    private let trigramFA: [String: [String]] = [
        "من می": ["خواهم", "توانم", "روم"],
        "تو می": ["توانی", "خواهی"],
        "ما می": ["توانیم", "خواهیم"],
        "شما می": ["توانید", "خواهید"],
        "او می": ["خواهد", "رود"],
        "به نظر": ["می‌رسد"],
        "در حال": ["حاضر"],
        "فکر می": ["کنم"],
        "خواهش می": ["کنم"],
        "اگر ممکنه": ["لطفاً"],
        "سلام وقت": ["بخیر"],
        "سلام روز": ["بخیر"],
        "برای شما": ["می‌فرستم"],
    ]
    private let sentenceStartFA: [String] = ["سلام", "من", "ما", "تو", "شما", "او", "امروز", "دیروز"]

    init(languageIdentifier: String) {
        self.languageIdentifier = languageIdentifier
        // Start progressive loading - initial phase is synchronous for fast startup
        startProgressiveLoading()
    }
    
    deinit {
        // Cancel all pending work items to prevent memory leaks
        invalidate()
    }
    
    /// Invalidate the engine and cancel all pending loads
    func invalidate() {
        accessQueue.sync(flags: .barrier) {
            isInvalidated = true
        }
        // Cancel all scheduled work items
        for workItem in loadWorkItems {
            workItem.cancel()
        }
        loadWorkItems.removeAll()
        // Clear cached content to free memory
        cachedUnigramENContent = nil
        cachedUnigramFAContent = nil
        cachedBigramContent = nil
        cachedTrigramContent = nil
        cachedFourgramContent = nil
    }
    
    /// Check if engine has been invalidated
    private var shouldContinueLoading: Bool {
        var result = false
        accessQueue.sync {
            result = !isInvalidated
        }
        return result
    }

    /// Suggest up to N words for a given prefix.
    func suggest(prefix: String, limit: Int = 10) -> [String] {
        let trimmed = prefix.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        let lower = trimmed.split(separator: " ").last?.lowercased() ?? trimmed.lowercased()
        var candidates: [(word: String, score: Double, source: String)] = []

        // 1) Special cases for contractions take precedence
        if let fixed = contractions[lower] {
            candidates.append((word: fixed, score: 2.0, source: "contraction"))
        }

        // 4) Frequency fallback from unigram (English) - thread-safe access
        if isEnglishLanguage() {
            var localTop: [String] = []
            var localUnigrams: [String: Int] = [:]
            var localMax: Int = 0
            
            accessQueue.sync {
                localTop = self.unigramTopEN
                localUnigrams = self.unigramEN
                localMax = self.maxUnigramEN
            }
            
            if !localTop.isEmpty {
                var results: [String] = []
                var scanned = 0
                let scanLimit = 10000
                for w in localTop {
                    if w.hasPrefix(lower) {
                        results.append(w)
                        if results.count >= 50 { break }
                    }
                    scanned += 1
                    if scanned >= scanLimit { break }
                }
                for w in results {
                    let s = 0.7 + frequencyBoostLocal(for: w, unigrams: localUnigrams, maxUnigram: localMax, isEnglish: true)
                    candidates.append((word: w, score: s, source: "unigram"))
                }
            }
        }

        // 5) Frequency fallback from unigram (Persian) - thread-safe access
        if isPersianLanguage() {
            var localTop: [String] = []
            var localUnigrams: [String: Int] = [:]
            var localMax: Int = 0
            
            accessQueue.sync {
                localTop = self.unigramTopFA
                localUnigrams = self.unigramFA
                localMax = self.maxUnigramFA
            }
            
            if !localTop.isEmpty {
                var results: [String] = []
                var scanned = 0
                let scanLimitFA = 10000
                for w in localTop {
                    if w.hasPrefix(lower) {
                        results.append(w)
                        if results.count >= 50 { break }
                    }
                    scanned += 1
                    if scanned >= scanLimitFA { break }
                }
                for w in results {
                    let s = 0.7 + frequencyBoostLocal(for: w, unigrams: localUnigrams, maxUnigram: localMax, isEnglish: false)
                    candidates.append((word: w, score: s, source: "unigram_fa"))
                }
            }
        }

        // Deduplicate by best score
        var best: [String: (score: Double, source: String)] = [:]
        for c in candidates {
            if let existing = best[c.word] {
                if c.score > existing.score {
                    best[c.word] = (c.score, c.source)
                }
            } else {
                best[c.word] = (c.score, c.source)
            }
        }

        let sorted = best
            .map { (word: $0.key, score: $0.value.score, source: $0.value.source) }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score { return lhs.word < rhs.word }
                return lhs.score > rhs.score
            }
            .map { $0.word }

        let final = Array(sorted.prefix(limit))
        Logger.debug("AutoSuggestEngine: suggest prefix='\(lower)' results=\(final.prefix(5)) total=\(final.count)")
        return final
    }
    
    /// Thread-safe frequency boost calculation using local copies
    private func frequencyBoostLocal(for word: String, unigrams: [String: Int], maxUnigram: Int, isEnglish: Bool) -> Double {
        let key = isEnglish ? word.lowercased() : word
        if let f = unigrams[key], maxUnigram > 0 {
            let normalized = min(1.0, Double(f) / Double(maxUnigram))
            return 0.5 * normalized
        }
        return 0.0
    }

    /// Suggest the next meaningful word based on context, only used after a suggestion is applied.
    /// - Parameters:
    ///   - contextBefore: Full text before cursor (after applied suggestion and a trailing space).
    ///   - lastWord: The word that was just applied by the user.
    ///   - limit: Maximum number of next-word suggestions to return.
    func suggestNextWord(contextBefore: String, lastWord: String, limit: Int = 6) -> [String] {
        let localeCode = Locale(identifier: languageIdentifier).languageCode ?? languageIdentifier
        let isEnglish = localeCode == "en" || languageIdentifier.lowercased().hasPrefix("en")
        let isPersian = (localeCode == "fa" || languageIdentifier.lowercased().hasPrefix("fa")) && AutoSuggestEngine.isPersianEnabled

        // Extract last two tokens from contextBefore
        let tokens = tokenize(contextBefore)
        let lastLower = lastWord.lowercased()
        let lastTwo = tokens.suffix(2).map { $0.lowercased() }
        let lastTwoKey = lastTwo.joined(separator: " ")
        let lastThree = tokens.suffix(3).map { $0.lowercased() }
        let lastThreeKey = lastThree.joined(separator: " ")

        // Determine if we're at a sentence start
        let isSentenceStart = isStartOfSentence(contextBefore)

        var candidates: [(word: String, score: Double)] = []
        
        // Thread-safe access to n-gram maps and unigrams
        var localBigrams: [String: [(String, Int)]] = [:]
        var localTrigrams: [String: [(String, Int)]] = [:]
        var localFourgrams: [String: [(String, Int)]] = [:]
        var localUnigramsEN: [String: Int] = [:]
        var localMaxEN: Int = 0
        
        accessQueue.sync {
            localBigrams = self.bigramNextEN
            localTrigrams = self.trigramNextEN
            localFourgrams = self.fourgramNextEN
            localUnigramsEN = self.unigramEN
            localMaxEN = self.maxUnigramEN
        }

        // 1) 4-gram based suggestions (English): use last three words
        if isEnglish, let quad = localFourgrams[lastThreeKey] {
            for (w, f) in quad {
                let boost = frequencyBoostLocal(for: w, unigrams: localUnigramsEN, maxUnigram: localMaxEN, isEnglish: true)
                candidates.append((w, 1.6 + normalizedENLocal(freq: f, maxUnigram: localMaxEN) + boost))
            }
        }
        // 2) Trigram-based suggestions
        if isEnglish, let tri = localTrigrams[lastTwoKey] {
            for (w, f) in tri {
                let boost = frequencyBoostLocal(for: w, unigrams: localUnigramsEN, maxUnigram: localMaxEN, isEnglish: true)
                candidates.append((w, 1.45 + normalizedENLocal(freq: f, maxUnigram: localMaxEN) + boost))
            }
        }
        if isPersian, let tri = trigramFA[lastTwoKey] {
            for w in tri { candidates.append((w, 1.5 + frequencyBoost(for: w))) }
        }

        // 3) Bigram-based suggestions: use the last word
        if isEnglish {
            if let local = bigramENLocal[lastLower] {
                for w in local {
                    let boost = frequencyBoostLocal(for: w, unigrams: localUnigramsEN, maxUnigram: localMaxEN, isEnglish: true)
                    candidates.append((w, 1.35 + boost))
                }
            } else if let bi = localBigrams[lastLower] {
                for (w, f) in bi {
                    let boost = frequencyBoostLocal(for: w, unigrams: localUnigramsEN, maxUnigram: localMaxEN, isEnglish: true)
                    candidates.append((w, 1.3 + normalizedENLocal(freq: f, maxUnigram: localMaxEN) + boost))
                }
            }
        }
        if isPersian, let bi = bigramFA[lastLower] {
            for w in bi { candidates.append((w, 1.3 + frequencyBoost(for: w))) }
        }

        // 4) Sentence-start defaults
        if isSentenceStart {
            let starts = isEnglish ? sentenceStartEN : (isPersian ? sentenceStartFA : [])
            for w in starts {
                let boost = isEnglish ? frequencyBoostLocal(for: w, unigrams: localUnigramsEN, maxUnigram: localMaxEN, isEnglish: true) : frequencyBoost(for: w)
                candidates.append((w, 1.2 + boost))
            }
        }

        // 5) Frequency fallback: general high-frequency words for flow
        if candidates.isEmpty {
            // Prefer top unigrams if available
            if isEnglish, !localUnigramsEN.isEmpty {
                let topUnigrams = localUnigramsEN.sorted { $0.value > $1.value }.prefix(20).map { $0.key }
                for w in topUnigrams {
                    let boost = frequencyBoostLocal(for: w, unigrams: localUnigramsEN, maxUnigram: localMaxEN, isEnglish: true)
                    candidates.append((w, 1.05 + boost))
                }
            }
            let commonEN = ["the","to","and","a","you","i","in","it","is","for","of","on","that","with"]
            let commonFA = ["و","به","در","از","من","تو","که","این","آن","برای"]
            let base = isEnglish ? commonEN : (isPersian ? commonFA : [])
            for w in base {
                let boost = isEnglish ? frequencyBoostLocal(for: w, unigrams: localUnigramsEN, maxUnigram: localMaxEN, isEnglish: true) : frequencyBoost(for: w)
                candidates.append((w, 1.0 + boost))
            }
        }

        // Deduplicate and sort by score, then word
        var best: [String: Double] = [:]
        for c in candidates {
            if let ex = best[c.word] { if c.score > ex { best[c.word] = c.score } }
            else { best[c.word] = c.score }
        }
        var sorted = best.map { (word: $0.key, score: $0.value) }
            .sorted { lhs, rhs in
                if lhs.score == rhs.score { return lhs.word < rhs.word }
                return lhs.score > rhs.score
            }
            .map { $0.word }

        // Adjust casing at sentence start for English
        if isSentenceStart && isEnglish {
            sorted = sorted.map { $0.prefix(1).uppercased() + $0.dropFirst() }
        }

        let final = Array(sorted.prefix(limit))
        Logger.debug("AutoSuggestEngine: suggestNextWord last3='\(lastThreeKey)' last2='\(lastTwoKey)' last1='\(lastLower)' results=\(final.prefix(6)) total=\(final.count)")
        return final
    }
    
    /// Thread-safe normalized frequency calculation
    private func normalizedENLocal(freq: Int, maxUnigram: Int) -> Double {
        guard maxUnigram > 0 else { return 0.0 }
        let normalized = min(1.0, Double(freq) / Double(maxUnigram))
        return 0.5 * normalized
    }

    /// Match the casing of the user's original input to the suggestion.
    func matchCasing(of original: String, to suggestion: String) -> String {
        // All uppercase
        if original == original.uppercased() && original.count > 1{
            return suggestion.uppercased()
        }
        // All lowercase
        if original == original.lowercased() {
            return suggestion.lowercased()
        }
        // Capitalized (first letter uppercase, rest lowercase)
        let first = original.prefix(1)
        let rest = original.dropFirst()
        if first == first.uppercased() && rest == rest.lowercased() {
            let sugFirst = suggestion.prefix(1).uppercased()
            let sugRest = suggestion.dropFirst().lowercased()
            return sugFirst + sugRest
        }
        // Mixed or unknown casing; return suggestion as-is
        return suggestion
    }

    // MARK: - Helpers

    private func preferredCheckerLanguage() -> String {
        // Try full identifier; if checker fails, fall back to a reasonable default
        if isValidLanguage(languageIdentifier) { return languageIdentifier }
        // Heuristic based on language code
        let code = Locale(identifier: languageIdentifier).languageCode ?? languageIdentifier
        switch code {
        case "fa": return "fa_IR"
        case "en": return "en_US"
        default: return "en_US"
        }
    }

    private func isEnglishLanguage() -> Bool {
        let code = Locale(identifier: languageIdentifier).languageCode ?? languageIdentifier
        return code == "en" || languageIdentifier.lowercased().hasPrefix("en")
    }

    private func isValidLanguage(_ lang: String) -> Bool {
        // UITextChecker.availableLanguages returns codes like "en_US"
        return UITextChecker.availableLanguages.contains(lang)
    }

    private func isPersianLanguage() -> Bool {
        if !AutoSuggestEngine.isPersianEnabled { return false }
        let code = Locale(identifier: languageIdentifier).languageCode ?? languageIdentifier
        return code == "fa" || languageIdentifier.lowercased().hasPrefix("fa")
    }

    private func stripQuotes(_ s: String) -> String {
        return s.trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }

    private func frequencyBoost(for word: String) -> Double {
        // Thread-safe access for Persian (used in static bigramFA/trigramFA lookups)
        if isPersianLanguage() {
            var localUnigrams: [String: Int] = [:]
            var localMax: Int = 0
            accessQueue.sync {
                localUnigrams = self.unigramFA
                localMax = self.maxUnigramFA
            }
            if let f = localUnigrams[word], localMax > 0 {
                let normalized = min(1.0, Double(f) / Double(localMax))
                return 0.5 * normalized
            }
        }
        // For English, prefer using frequencyBoostLocal with local copies
        if isEnglishLanguage() {
            var localUnigrams: [String: Int] = [:]
            var localMax: Int = 0
            accessQueue.sync {
                localUnigrams = self.unigramEN
                localMax = self.maxUnigramEN
            }
            if let f = localUnigrams[word.lowercased()], localMax > 0 {
                let normalized = min(1.0, Double(f) / Double(localMax))
                return 0.5 * normalized
            }
        }
        return 0.0
    }

    private func tokenize(_ text: String) -> [String] {
        // Simple whitespace split, trimming punctuation
        let separators = CharacterSet.whitespacesAndNewlines
        let parts = text.components(separatedBy: separators)
        let punct = CharacterSet.punctuationCharacters.union(CharacterSet.symbols)
        return parts
            .map { $0.trimmingCharacters(in: punct) }
            .filter { !$0.isEmpty }
    }

    private func isStartOfSentence(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return true }
        guard let last = trimmed.last else { return true }
        return [".","!","?","\n"].contains(last)
    }

    // MARK: - Progressive Loading Implementation
    
    private func startProgressiveLoading() {
        // Initial phase loads synchronously for immediate availability
        if isEnglishLanguage() {
            loadUnigramsENProgressive(phase: .initial)
            didLoadEN = true
            scheduleNextPhaseEN()
        }
        
        if isPersianLanguage() {
            loadUnigramsFAProgressive(phase: .initial)
            didLoadFA = true
            scheduleNextPhaseFA()
        }
    }
    
    private func scheduleNextPhaseEN() {
        guard shouldContinueLoading else { return }
        
        let nextPhase: LoadPhase
        switch currentPhaseEN {
        case .initial: nextPhase = .fast
        case .fast: nextPhase = .medium
        case .medium: nextPhase = .complete
        case .complete: return // All phases complete
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.shouldContinueLoading else { return }
            self.loadPhaseEN(nextPhase)
        }
        
        accessQueue.sync(flags: .barrier) {
            loadWorkItems.append(workItem)
        }
        
        loadQueue.asyncAfter(deadline: .now() + nextPhase.delay, execute: workItem)
    }
    
    private func scheduleNextPhaseFA() {
        guard shouldContinueLoading else { return }
        
        let nextPhase: LoadPhase
        switch currentPhaseFA {
        case .initial: nextPhase = .fast
        case .fast: nextPhase = .medium
        case .medium: nextPhase = .complete
        case .complete: return // All phases complete
        }
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self, self.shouldContinueLoading else { return }
            self.loadPhaseFAProgressive(nextPhase)
        }
        
        accessQueue.sync(flags: .barrier) {
            loadWorkItems.append(workItem)
        }
        
        loadQueue.asyncAfter(deadline: .now() + nextPhase.delay, execute: workItem)
    }
    
    private func loadPhaseEN(_ phase: LoadPhase) {
        guard shouldContinueLoading else { return }
        
        // Load unigrams for this phase
        loadUnigramsENProgressive(phase: phase)
        
        // Load n-grams based on phase
        switch phase {
        case .initial:
            break // No n-grams in initial phase
        case .fast:
            loadNextMapsENProgressive(ngramCount: 2, lineLimit: phase.ngramLineLimit)
        case .medium:
            loadNextMapsENProgressive(ngramCount: 2, lineLimit: phase.ngramLineLimit)
            loadNextMapsENProgressive(ngramCount: 3, lineLimit: phase.ngramLineLimit)
        case .complete:
            loadNextMapsENProgressive(ngramCount: 2, lineLimit: phase.ngramLineLimit)
            loadNextMapsENProgressive(ngramCount: 3, lineLimit: phase.ngramLineLimit)
            loadNextMapsENProgressive(ngramCount: 4, lineLimit: phase.ngramLineLimit)
            // Clear cached content after complete loading
            cachedUnigramENContent = nil
            cachedBigramContent = nil
            cachedTrigramContent = nil
            cachedFourgramContent = nil
        }
        
        currentPhaseEN = phase
        Logger.debug("AutoSuggestEngine: English phase \(phase.rawValue) complete - unigrams=\(unigramEN.count), bigrams=\(bigramNextEN.count), trigrams=\(trigramNextEN.count), fourgrams=\(fourgramNextEN.count)")
        
        // Schedule next phase
        scheduleNextPhaseEN()
    }
    
    private func loadPhaseFAProgressive(_ phase: LoadPhase) {
        guard shouldContinueLoading else { return }
        
        loadUnigramsFAProgressive(phase: phase)
        currentPhaseFA = phase
        
        if phase == .complete {
            cachedUnigramFAContent = nil
        }
        
        Logger.debug("AutoSuggestEngine: Persian phase \(phase.rawValue) complete - unigrams=\(unigramFA.count)")
        
        // Schedule next phase
        scheduleNextPhaseFA()
    }
    
    private func loadUnigramsENProgressive(phase: LoadPhase) {
        // Load or use cached content
        if cachedUnigramENContent == nil {
            guard let url = Bundle(for: KeyboardViewController.self).url(forResource: "1grams_english", withExtension: "csv") else {
                Logger.debug("AutoSuggestEngine: 1grams_english.csv not found in bundle")
                return
            }
            do {
                let data = try Data(contentsOf: url)
                cachedUnigramENContent = String(data: data, encoding: .utf8)
            } catch {
                Logger.debug("AutoSuggestEngine: Failed loading 1grams_english.csv - \(error)")
                return
            }
        }
        
        guard let content = cachedUnigramENContent else { return }
        
        let limit = phase.unigramLimit
        var localUnigrams: [String: Int] = [:]
        var localTop: [String] = []
        var maxF = 0
        var added = 0
        
        // Copy existing data for incremental loading
        accessQueue.sync {
            localUnigrams = self.unigramEN
            localTop = self.unigramTopEN
            maxF = self.maxUnigramEN
            added = localTop.count
        }
        
        // Skip if we've already loaded enough
        if added >= limit { return }
        
        var lineIndex = 0
        for rawLine in content.split(separator: "\n") {
            guard shouldContinueLoading else { return }
            
            lineIndex += 1
            // Skip lines we've already processed
            if lineIndex <= added { continue }
            
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            if line.lowercased().hasPrefix("ngram,") { continue } // header
            
            let cols = line.split(separator: ",")
            guard cols.count >= 2 else { continue }
            let ngram = String(cols[0]).lowercased()
            let freqStr = String(cols[1]).trimmingCharacters(in: .whitespaces)
            let freq = Int(freqStr) ?? 0
            guard !ngram.isEmpty, freq > 0 else { continue }
            if ngram.contains(" ") { continue }
            
            localUnigrams[ngram] = freq
            if added < limit {
                localTop.append(ngram)
                added += 1
            }
            if freq > maxF { maxF = freq }
            
            if added >= limit { break }
        }
        
        // Thread-safe update
        accessQueue.sync(flags: .barrier) {
            self.unigramEN = localUnigrams
            self.unigramTopEN = localTop
            self.maxUnigramEN = maxF
        }
    }
    
    private func loadUnigramsFAProgressive(phase: LoadPhase) {
        // Load or use cached content
        if cachedUnigramFAContent == nil {
            guard let url = Bundle(for: KeyboardViewController.self).url(forResource: "farsi", withExtension: "txt") else {
                Logger.debug("AutoSuggestEngine: farsi.txt not found in bundle")
                return
            }
            do {
                let data = try Data(contentsOf: url)
                cachedUnigramFAContent = String(data: data, encoding: .utf8)
            } catch {
                Logger.debug("AutoSuggestEngine: Failed loading farsi.txt - \(error)")
                return
            }
        }
        
        guard let content = cachedUnigramFAContent else { return }
        
        let limit = phase.unigramLimit
        var localUnigrams: [String: Int] = [:]
        var localTop: [String] = []
        var added = 0
        
        // Copy existing data for incremental loading
        accessQueue.sync {
            localUnigrams = self.unigramFA
            localTop = self.unigramTopFA
            added = localTop.count
        }
        
        // Skip if we've already loaded enough
        if added >= limit { return }
        
        var currentFreq = unigramCapFA - added
        var lineIndex = 0
        
        for rawLine in content.split(separator: "\n") {
            guard shouldContinueLoading else { return }
            
            lineIndex += 1
            // Skip lines we've already processed
            if lineIndex <= added { continue }
            
            let word = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if word.isEmpty { continue }
            
            if localUnigrams[word] == nil {
                localUnigrams[word] = currentFreq
                localTop.append(word)
                added += 1
                currentFreq = max(1, currentFreq - 1)
                if added >= limit { break }
            }
        }
        
        // Thread-safe update
        let maxFA = localUnigrams.values.max() ?? 0
        accessQueue.sync(flags: .barrier) {
            self.unigramFA = localUnigrams
            self.unigramTopFA = localTop
            self.maxUnigramFA = maxFA
        }
    }
    
    private func loadNextMapsENProgressive(ngramCount: Int, lineLimit: Int) {
        guard [2,3,4].contains(ngramCount), shouldContinueLoading else { return }
        
        let name = "\(ngramCount)grams_english"
        
        // Get or load cached content
        let content: String?
        switch ngramCount {
        case 2:
            if cachedBigramContent == nil {
                cachedBigramContent = loadFileContent(name: name)
            }
            content = cachedBigramContent
        case 3:
            if cachedTrigramContent == nil {
                cachedTrigramContent = loadFileContent(name: name)
            }
            content = cachedTrigramContent
        case 4:
            if cachedFourgramContent == nil {
                cachedFourgramContent = loadFileContent(name: name)
            }
            content = cachedFourgramContent
        default:
            content = nil
        }
        
        guard let fileContent = content else { return }
        
        // Get current count
        var currentCount = 0
        accessQueue.sync {
            switch ngramCount {
            case 2: currentCount = bigramNextEN.count
            case 3: currentCount = trigramNextEN.count
            case 4: currentCount = fourgramNextEN.count
            default: break
            }
        }
        
        // Copy existing maps for local modification
        var localBigrams: [String: [(String, Int)]] = [:]
        var localTrigrams: [String: [(String, Int)]] = [:]
        var localFourgrams: [String: [(String, Int)]] = [:]
        
        accessQueue.sync {
            localBigrams = self.bigramNextEN
            localTrigrams = self.trigramNextEN
            localFourgrams = self.fourgramNextEN
        }
        
        var lineCount = 0
        for rawLine in fileContent.split(separator: "\n") {
            guard shouldContinueLoading else { return }
            
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty { continue }
            if line.lowercased().hasPrefix("ngram,") { continue }
            
            let cols = line.split(separator: ",")
            guard cols.count >= 2 else { continue }
            let ngram = String(cols[0]).lowercased()
            let freqStr = String(cols[1]).trimmingCharacters(in: .whitespaces)
            let freq = Int(freqStr) ?? 0
            guard freq > 0 else { continue }
            
            let tokens = ngram.split(separator: " ").map { String($0) }
            guard tokens.count == ngramCount else { continue }
            let contextTokens = tokens.dropLast()
            let nextToken = tokens.last!
            let contextKey = contextTokens.joined(separator: " ")
            
            switch ngramCount {
            case 2:
                appendNextLocal(into: &localBigrams, key: contextKey, next: nextToken, freq: freq, cap: 10)
            case 3:
                appendNextLocal(into: &localTrigrams, key: contextKey, next: nextToken, freq: freq, cap: 10)
            case 4:
                appendNextLocal(into: &localFourgrams, key: contextKey, next: nextToken, freq: freq, cap: 10)
            default: break
            }
            
            lineCount += 1
            if lineCount >= lineLimit { break }
        }
        
        // Thread-safe update
        accessQueue.sync(flags: .barrier) {
            switch ngramCount {
            case 2: self.bigramNextEN = localBigrams
            case 3: self.trigramNextEN = localTrigrams
            case 4: self.fourgramNextEN = localFourgrams
            default: break
            }
        }
    }
    
    private func loadFileContent(name: String) -> String? {
        guard let url = Bundle(for: KeyboardViewController.self).url(forResource: name, withExtension: "csv") else {
            Logger.debug("AutoSuggestEngine: \(name).csv not found in bundle")
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return String(data: data, encoding: .utf8)
        } catch {
            Logger.debug("AutoSuggestEngine: Failed loading \(name).csv - \(error)")
            return nil
        }
    }
    
    private func appendNextLocal(into map: inout [String: [(String, Int)]], key: String, next: String, freq: Int, cap: Int) {
        var arr = map[key] ?? []
        if let idx = arr.firstIndex(where: { $0.0 == next }) {
            arr[idx] = (next, max(arr[idx].1, freq))
        } else {
            arr.append((next, freq))
        }
        arr.sort { $0.1 > $1.1 }
        if arr.count > cap { arr = Array(arr.prefix(cap)) }
        map[key] = arr
    }

    private func normalizedEN(freq: Int) -> Double {
        var localMax: Int = 0
        accessQueue.sync {
            localMax = self.maxUnigramEN
        }
        guard localMax > 0 else { return 0.0 }
        let normalized = min(1.0, Double(freq) / Double(localMax))
        return 0.5 * normalized
    }
}

/// Provider that caches engines per language and handles lifecycle.
actor AutoSuggestProvider {
    static let shared = AutoSuggestProvider()
    private init() {}

    private var engines: [String: AutoSuggestEngine] = [:]
    private var loading: [String: Bool] = [:]

    func getEngine(for localeIdentifier: String) async -> AutoSuggestEngine? {
        let key = Locale(identifier: localeIdentifier).languageCode ?? localeIdentifier
        if let e = engines[key] { return e }
        if loading[key] == true { return nil }
        loading[key] = true
        let engine = AutoSuggestEngine(languageIdentifier: localeIdentifier)
        engines[key] = engine
        loading[key] = false
        return engine
    }

    func unload(languageIdentifier: String? = nil) {
        loading.removeAll()
        if let lang = languageIdentifier {
            let key = Locale(identifier: lang).languageCode ?? lang
            // Invalidate engine before removing to cancel pending work items
            engines[key]?.invalidate()
            engines[key] = nil
        } else {
            // Invalidate all engines before removing
            for engine in engines.values {
                engine.invalidate()
            }
            engines.removeAll()
        }
    }
}