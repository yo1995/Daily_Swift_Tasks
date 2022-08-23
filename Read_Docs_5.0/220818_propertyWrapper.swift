import Foundation
import Combine

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

@propertyWrapper
class SlowlyPublished<Value> {
    var wrappedValue: Value {
        get { subject.value }
        set { subject.value = newValue }
    }
    
    private let subject: CurrentValueSubject<Value, Never>
    private let publisher: AnyPublisher<Value, Never>
    
    var projectedValue: AnyPublisher<Value, Never> {
        get { publisher }
    }
    
    init(wrappedValue: Value, debounce: DispatchQueue.SchedulerTimeType.Stride) {
        self.subject = CurrentValueSubject(wrappedValue)
        self.publisher = self.subject
            .debounce(for: debounce, scheduler: DispatchQueue.global())
            .eraseToAnyPublisher()
    }
}

struct Book {
    var name: String
    @Percent var progress: Double
    @ClampedInt(minimum: 0, maximum: 100) var value = 19
    @SlowlyPublished(debounce: 0.3) var bouncyValue = 1
}

var book = Book(
    name: "SwiftUI",
    progress: 0.9,
    value: 102
)

var cancellables = Set<AnyCancellable>()
book.$bouncyValue
    .sink { value in
        print(value)
    }
    .store(in: &cancellables)

book.progress = -0.2
book.bouncyValue = 2
book.bouncyValue = 3
book.bouncyValue = 4
book.bouncyValue = 100

print(book.$progress)
print(book.value)

// sleep(1)
RunLoop.main.run(until: Date(timeIntervalSinceNow: 1))
