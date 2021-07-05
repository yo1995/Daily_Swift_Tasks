import Cocoa

let words = ["abc","deq","mee","aqq","dkd","ccc"]
let pattern = "abb"

func findAndReplacePattern(_ words: [String], _ pattern: String) -> [String] {
    let matchesPattern: (String) -> Bool = { word in
        var wordToPattern = [Character: Character?]()
        var patternToWord = [Character: Character?]()
        for (cw, cp) in zip(word, pattern) {
            if (wordToPattern[cw] ?? cp) != cp || (patternToWord[cp] ?? cw) != cw {
                return false
            }
            wordToPattern[cw] = cp
            patternToWord[cp] = cw
        }
        return true
    }
    return words.filter(matchesPattern)
}

print(findAndReplacePattern(words, pattern))
