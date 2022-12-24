[![Swift](https://github.com/Periodic-Apps/swift-data-reader/actions/workflows/swift.yml/badge.svg)](https://github.com/Periodic-Apps/swift-data-reader/actions/workflows/swift.yml)

# SwiftDataReader

SwiftDataReader is a swift library which simplifies the work of reading values 
from an instance of Foundation's `Data` type. 

## Examples

```swift
var reader = DataReader(data: Data([1,2,3,4,5,6,7,8]))
let myInt: Int32 = reader.readValue()!
let myOtherInt: Int32 = reader.readValue()!
```

In this example, `readValue(type:)` infers the type and number of bytes
to read from the `Data` object from the type of the destination
variable.

If the type cannot be inferred, it can be passed as an argument
to either `peekValue(type:)` or `readValue(type:)`.

```swift
var reader = DataReader(data: Data([1]))
let value = reader.readValue(type: UInt8.self)!
```

### Strings

```swift
let str = "🤞 this is a utf-8 string ⛵️"
var data = Data([UInt8(str.lengthOfBytes(using: .utf8)),0,0,0]) // str count
data.append(str.data(using: .utf8)!) // the string to be read back

var reader = DataReader(data: data)

let strLen: UInt32 = reader.readValue()!
let testStr: String = reader.readValue(count: Int(strLen))!
```

### Arrays

```swift
let reader = DataReader(data: Data([1,0,0,0, 2,0,0,0, 3,0,0,0, 4,0,0,0]))
let value: [Int32] = reader.peekValue(count: 3)!
```

### Custom Types

```swift
struct Foo: DefaultInitializable, Equatable {
  var x: Int32 = 0
  var y: Int32 = 0
}
var reader = DataReader(data: Data([1,0,0,0,2,0,0,0]))
let f:Foo = reader.readValue()!
```
