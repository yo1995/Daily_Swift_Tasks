import Foundation

protocol abs {
    var absoluteValue: Double {get}
}

extension Double: abs {
    var absoluteValue: Double {
        return self > 0 ? self : -1 * self
    }
}

let d: Double = -41.3
print(d.absoluteValue)