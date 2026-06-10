import Foundation

enum WordState: String, CaseIterable {
    case wrong = "wrong"
    case corrected = "corrected"
    case normal = "normal"
    case spell = "spell"
}

struct WordOutput {
    let value: String
    let state: WordState
    
    init(value: String, state: WordState) {
        self.value = value
        self.state = state
    }
}


