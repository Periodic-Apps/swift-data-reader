import XCTest
import SwiftDataReader

final class SwiftDataReaderTests: XCTestCase {
  func peek<V>(for type: V.Type, from reader: DataReader) -> V? {
    reader.peekValue()
  }
  
  func peek<V>(for type: V.Type, from data: Data) -> V? {
    peek(for: type, from: DataReader(data: data))
  }
  
  func peek<V>(for type: V.Type, from bytes: [UInt8]) -> V? {
    peek(for: type, from: Data(bytes))
  }
  
  func read<V>(for type: V.Type, from reader: inout DataReader) -> V? {
    reader.readValue()
  }
  
  func testPeaking() {
    XCTAssertEqual(peek(for: UInt8.self, from: [1,0,0,0]), 1)
    XCTAssertEqual(peek(for: UInt16.self, from: [1,2,0,0]), 513)
    XCTAssertEqual(peek(for: UInt32.self, from: [1,2,3,0]), 197121)
    XCTAssertEqual(peek(for: UInt32.self, from: [1,2,3,4]), 67305985)
    
    
    let data = Data([255,255,255,255,255,255,255,255])
    XCTAssertEqual(peek(for: UInt64.self, from: data), 18446744073709551615)
    XCTAssertEqual(peek(for: Int64.self, from: data), -1)
    
    XCTAssertEqual(peek(for: UInt8.self, from: data), 255)
    XCTAssertEqual(peek(for: Int8.self, from: data), -1)
    
    XCTAssertEqual(peek(for: UInt16.self, from: data), 65535)
    XCTAssertEqual(peek(for: Int16.self, from: data), -1)
    
    XCTAssertEqual(peek(for: UInt32.self, from: data), 4294967295)
    XCTAssertEqual(peek(for: Int32.self, from: data), -1)
  }
  
  func testPeakString() {
    
    let str = "🤞 this is a utf-8 string ⛵️"
    var data = Data([UInt8(str.lengthOfBytes(using: .utf8)),0,0,0]) // str count
    data.append(str.data(using: .utf8)!) // the string to be read back
    data.append(contentsOf: [1,2,3,4]) // some other data
    
    var reader = DataReader(data: data)
    
    let strLen: UInt32 = reader.readValue()!
    let testStr: String = reader.readValue(count: Int(strLen))!
    let _: Int32 = reader.readValue()!
    
    XCTAssertEqual(str, testStr)
    XCTAssertTrue(reader.isAtEnd)
  }
  
  /// Test what happens when peaking and there isn't enough data
  func testPeakingUnderrun() {
    let reader = DataReader(data: Data([1,2,3]))
    XCTAssertNil(peek(for: Int32.self, from: reader))
  }
  
  func testReading() {
    var reader = DataReader(data: Data([1,2,3,4]))
    XCTAssertEqual(read(for: UInt8.self, from: &reader), 1)
    XCTAssertEqual(read(for: UInt8.self, from: &reader), 2)
    XCTAssertEqual(read(for: UInt8.self, from: &reader), 3)
    XCTAssertEqual(read(for: UInt8.self, from: &reader), 4)
  }
 
  func testIsAtEnd() {
    let reader = DataReader(data: Data())
    XCTAssertTrue(reader.isAtEnd)
    
    let reader2 = DataReader(data: Data([1,2]))
    XCTAssertFalse(reader2.isAtEnd)
  }
  
  func testCustomType() {
    struct Foo: Equatable {
      var x: Int32 = 0
      var y: Int32 = 0
    }
    
    var reader = DataReader(data: Data([1,0,0,0,2,0,0,0]))
    let f: Foo = reader.readValue()!
    XCTAssertEqual(f, Foo(x: 1, y: 2))
  }
  
  func testReadChar() {
    let reader = DataReader(data: Data([43, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]))
    let c: Character? = reader.peekValue()
//    XCTAssertEqual(c, "+")
  }
  
  func testConcreteType() {
    var reader = DataReader(data: Data([1]))
    let value = reader.readValue(type: UInt8.self)!
    XCTAssertEqual(value, 1)
  }
  
  func testReadArrays() {
    var reader = DataReader(data: Data([1,0,0,0, 2,0,0,0, 3,0,0,0, 4,0,0,0]))
    let value: [Int32] = reader.peekValue(count: 3)!
    XCTAssertEqual(value, [1,2,3])
            
    let value1: [Int32] = reader.readValue(count: 2)!
    let value2: [Int32] = reader.readValue(count: 2)!
    XCTAssertEqual(value1, [1,2])
    XCTAssertEqual(value2, [3,4])
  }
}
