
func one(a: Int) -> Int {
    return a
}

func one(a: Int) -> Void {
    print(a)
    return
}

let _: Void = one(a: 1)  // will work, print a
let _: Int = one(a: 1)  // will also work

// error: ambiguous use of 'one(a:)'
let _ = one(a: 1)  // won't work!
one(a: 1)  // won't work
