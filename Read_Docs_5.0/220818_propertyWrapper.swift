import Foundation

// Property Wrappers
//
// E.g., @State, @Binding, @ObservedObject

@propertyWrapper struct Percent {
    var storage: Double

    var wrappedValue: Double {
        get {
            max(min(storage, 1), 0)
        }
        set {
            storage = newValue
        }
    }

    var projectedValue: Double {
        storage
    }

    init(wrappedValue: Double) {
        storage = wrappedValue
    }
}

@propertyWrapper struct ClampedInt {
    var minimumValue: Int
    var maximumValue: Int
    var storage: Int
    
    var wrappedValue: Int {
        get {
            max(min(storage, maximumValue), minimumValue)
        }
        set {
            storage = newValue
        }
    }

    init(wrappedValue: Int, minimum: Int, maximum: Int) {
        storage = wrappedValue
        minimumValue = minimum
        maximumValue = maximum
    }
}

struct Book {
    var name: String
    @Percent var progress: Double
    @ClampedInt(minimum: 0, maximum: 100) var value = 19
}

var book = Book(
    name: "SwiftUI",
    progress: 0.9,
    value: 102
)
book.progress = -0.2
print(book.$progress)
print(book.value)
