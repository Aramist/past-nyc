import Foundation

var greeting = "Hello, playground"
let test = "1873 & 1945"

let reg = test.range(of: "[0-9]{4}", options: .regularExpression)

test[reg!]
