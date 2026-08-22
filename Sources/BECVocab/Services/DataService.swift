import Foundation
import Observation

@Observable
final class DataService {
    var words: [Word] = []
    var currentIndex: Int = 0
    var searchQuery: String = ""
    var searchResults: [Int] = []
    var bookmarkIndex: Int = -1

    private let bookmarksKey = "bec_vocab_bookmark"

    var currentWord: Word? {
        guard !words.isEmpty, currentIndex < words.count else { return nil }
        return words[currentIndex]
    }

    var filteredIndices: [Int] {
        if searchQuery.isEmpty { return Array(0..<words.count) }
        return searchResults
    }

    var filteredWords: [Word] {
        filteredIndices.map { words[$0] }
    }

    var totalCount: Int { words.count }
    var filteredCount: Int { filteredIndices.count }

    var progressPercent: Double {
        guard totalCount > 0 else { return 0 }
        return Double(bookmarkIndex + 1) / Double(totalCount) * 100
    }

    init() {
        loadWords()
        loadBookmark()
    }

    private func loadWords() {
        guard let url = Bundle.module.url(forResource: "bec_data", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Word].self, from: data) else {
            print("Failed to load word data")
            return
        }
        words = decoded
        print("Loaded \(words.count) words")
    }

    private func loadBookmark() {
        bookmarkIndex = UserDefaults.standard.integer(forKey: bookmarksKey)
        if bookmarkIndex > 0 && bookmarkIndex < words.count {
            currentIndex = bookmarkIndex
        }
    }

    func saveBookmark() {
        bookmarkIndex = currentIndex
        UserDefaults.standard.set(bookmarkIndex, forKey: bookmarksKey)
    }

    func search(_ query: String) {
        searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if searchQuery.isEmpty {
            searchResults = []
            return
        }
        searchResults = words.enumerated().compactMap { idx, word in
            if word.en.lowercased().contains(searchQuery) || word.zh.contains(searchQuery) {
                return idx
            }
            return nil
        }
        if !searchResults.isEmpty {
            currentIndex = searchResults[0]
        }
    }

    func goNext() {
        let list = filteredIndices
        if let pos = list.firstIndex(of: currentIndex), pos + 1 < list.count {
            currentIndex = list[pos + 1]
        }
    }

    func goPrevious() {
        let list = filteredIndices
        if let pos = list.firstIndex(of: currentIndex), pos > 0 {
            currentIndex = list[pos - 1]
        }
    }

    func goToBookmark() {
        if bookmarkIndex >= 0 && bookmarkIndex < words.count {
            currentIndex = bookmarkIndex
        }
    }
}