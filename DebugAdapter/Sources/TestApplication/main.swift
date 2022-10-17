import Foundation
import Dispatch

class MyClass {
    var names = ["John", "Jane", "Joan"]
    var numbers = [12, 13e12, 11.2]
    var isTrue = true
    var isFalse = false
    
    func doThing() {
        dispatchMain()
    }
}

let myObj = MyClass()
myObj.doThing()
