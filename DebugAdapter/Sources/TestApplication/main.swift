import Foundation
import Dispatch

class MyClass {
    var names = ["John", "Jane", "Joan"]
    var numbers = [12, 13e12, 11.2]
    var isTrue = true
    var isFalse = false
    
    enum MyError: Error {
        case foobar
    }
    
    func doThing() {
        let foo = 12
        let bar = "foo"
        let bin = [12, 14, 18]
        
        print("Doing the thing!")
        do {
            throw MyError.foobar
        }
        catch {
        }
    }
}

print("Starting up!")

let myObj = MyClass()
myObj.doThing()

print("Finished!")
