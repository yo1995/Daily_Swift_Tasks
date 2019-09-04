func RJYRobRedPocket(_ balance: Int) {
    if balance <= 1 {
        return
    }
    let rich = Int.random(in: 1..<balance)
    print("Rich RJY get \(Double(rich)/100.0)")
    RJYRobRedPocket(balance - rich)
}

RJYRobRedPocket(20000)
