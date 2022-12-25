import Foundation

/// `DataReader` makes it possible to read multiple sequential
/// values from a single Foundation `Data` object.
///
/// Example
/// ```
/// var reader = DataReader(data: Data([1,2,3,4,5,6,7,8]))
/// let myInt: Int32 = reader.readValue()!
/// let myOtherInt: Int32 = reader.readValue()!
/// ```
/// In this example, ``readValue(type:)`` infers the type and number of bytes
/// to read from the `Data` object from the type of the destination
/// variable.
///
/// If the type cannot be inferred, it can be passed as an argument
/// to either ``peekValue(type:)`` or ``readValue(type:)``.
///
/// ```
/// var reader = DataReader(data: Data([1]))
/// let value = reader.readValue(type: UInt8.self)!
/// ```
///
/// More complex types can be parsed from the data as well:
///
/// ```
/// struct Foo: DefaultInitializable, Equatable {
///   var x: Int32 = 0
///   var y: Int32 = 0
/// }
///
/// var reader = DataReader(data: Data([1,0,0,0,2,0,0,0]))
/// let f: Foo = reader.readValue()!
/// ```
public struct DataReader {
  private let data: Data
  private var position: Data.Index
  
  public init(data: Data) {
    self.data = data
    self.position = data.startIndex
  }
    
  /// Read a value of the inferred type `T` from the data.
  /// If a value of this type cannot be read `nil` is returned.
  public mutating func readValue<T>(type: T.Type = T.self) -> T? {
    defer {
      position += MemoryLayout<T>.size
    }

    return peekValue()
  }
  
  /// Read an array of values for an inferred type `T` from the data.
  /// If `count` values cannot be read `nil` is returned
  public mutating func readValue<T>(count elementCount: Int) -> [T]? {
    defer {
      position += (elementCount * MemoryLayout<T>.size)
    }

    return peekValue(count: elementCount)
  }
      
  /// Read a `String` with length `count`.
  @available(macOS 11.0, *)
  @available(iOS 14.0, *)
  public mutating func readValue(count byteCount: Int) -> String? {
    defer {
      position += byteCount
    }

    return peekValue(count: byteCount)
  }
  
  /// Peek into the data to read a type which conform to `RawRepresentable`
  /// This is typically used by enum types.
  public mutating func readValue<T>(type: T.Type = T.self) -> T? where T: RawRepresentable {
    defer {
      position += MemoryLayout<T.RawValue>.size
    }

    return peekValue()
  }
    
  /// Peek into the Data for the inferred type `T` to see what it's value
  /// is without consuming the data. If a value of type cannot be read
  /// `nil` is returned.
  public func peekValue<T>(type: T.Type = T.self) -> T? {
    let valuePtr = UnsafeMutablePointer<T>.allocate(capacity: 1)
    
    defer {
      valuePtr.deallocate()
    }
    
    let start = position
    let end = position + MemoryLayout<T>.size
    
    guard end <= data.endIndex else {
      return nil
    }
    
    // TODO: fix replace deprecated method usage
    data[start..<end].withUnsafeBytes { bytes in
      let count = (end - start) / MemoryLayout<T>.size // shouldn't this also be 1?
      valuePtr.initialize(from: bytes, count: count)
    }
    
    return valuePtr.pointee
  }
  
  /// Read an `Array` of `T` instances with length `count` without
  /// advancing the position in the data. If the entire array cannot
  /// be read `nil` is returned
  public func peekValue<T>(count elementCount: Int) -> [T]? {
    let valuePtr = UnsafeMutablePointer<T>.allocate(capacity: elementCount)
    
    let start = position
    let end = position + MemoryLayout<T>.size * elementCount
    
    guard end <= data.endIndex else {
      return nil
    }
    
    data[start..<end].withUnsafeBytes { dataPtr in
      valuePtr.initialize(from: dataPtr, count: elementCount)
    }
    
    let array = Array(UnsafeMutableBufferPointer(start: valuePtr, count: elementCount))
    valuePtr.deallocate()
    return array
  }
    
  /// Peek into the Data for a `String` of byte length `count` without
  /// consuming the data. If a value of type cannot be read `nil` is returned.
  @available(macOS 11.0, *)
  @available(iOS 14.0, *)
  public func peekValue(count byteCount: Int) -> String? {
    let start = position
    let end = position + /* MemoryLayout<String>.size * */ byteCount // sus
    
    guard end <= data.endIndex else {
      return nil
    }
    
    let value = String(unsafeUninitializedCapacity: byteCount) { buffer in
      data[start..<end].withUnsafeBytes { dataPtr in
        dataPtr.copyBytes(to: buffer)
      }
    }
    
    return value
  }
  
  /// Peek into the data to read a type which conform to `RawRepresentable`
  /// This is typically used by enum types.
  public func peekValue<T: RawRepresentable>() -> T? {
    let start = position
    let end = position * MemoryLayout<T.RawValue>.size
    
    guard end <= data.endIndex else {
      return nil
    }
    
    let valuePtr = UnsafeMutablePointer<T.RawValue>.allocate(capacity: 1)
    defer {
      valuePtr.deallocate()
    }
    
    data[start..<end].withUnsafeBytes { bytes in
      valuePtr.initialize(from: bytes, count: 1)
    }
    
    let value = T(rawValue: valuePtr.pointee)
    return value
  }
  
  /// Returns `true` if there is no more data to be read.
  /// Returns `false` if there is still data that can be read.
  public var isAtEnd: Bool {
    position >= data.endIndex
  }
}
