import Foundation

extension ShadowDecoder {
    /// Keyed container for the CSV shadow decoder.
    ///
    /// This container lets you randomly access all the records on a CSV or all th efields within a single record.
    struct KeyedContainer<Key>: KeyedDecodingContainerProtocol where Key:CodingKey {
        /// The representation of the decoding process point-in-time.
        private let decoder: ShadowDecoder
        /// The container's target (or level).
        private let focus: Focus
        /// Creates a keyed container only if the passed decoder's coding path is valid.
        ///
        /// This initializer only allows the creation of a container when the decoder's coding path:
        /// - is empty (implying a keyed container traversing the CSV file),
        /// - has a single coding key with an integer value (implying a keyed container traversing a single CSV row).
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        init(decoder: ShadowDecoder) throws {
            switch decoder.codingPath.count {
            case 0:  self.focus = .file
            case 1:  let r = try decoder.codingPath[0].intValue ?! DecodingError.invalidRowKey(codingPath: decoder.codingPath)
            self.focus = .row(r)
            default: throw DecodingError.invalidContainerRequest(codingPath: decoder.codingPath)
            }
            self.decoder = decoder
        }
        /// Convenience initializer for performance purposes that doesn't check the coding path and expects a row index.
        /// - parameter decoder: The `Decoder` instance in charge of decoding the CSV data.
        internal init(unsafeDecoder decoder: ShadowDecoder, rowIndex: Int) {
            self.decoder = decoder
            self.focus = .row(rowIndex)
        }
        
        var codingPath: [CodingKey] {
            self.decoder.codingPath
        }
        
        var allKeys: [Key] {
            switch self.focus {
            case .file:
                guard let numRows = self.decoder.source.numRows, numRows > 0 else { return [] }
                return (0..<numRows).compactMap { Key(intValue: $0) }
            case .row:
                let numFields = self.decoder.source.numFields
                guard numFields > 0 else { return [] }
                
                let numberKeys = (0..<numFields).compactMap { Key(intValue: $0) }
                guard numberKeys.isEmpty else { return numberKeys }
                
                guard let headers = self.decoder.source.headers, !headers.isEmpty else { return [] }
                return headers.compactMap { Key(stringValue: $0) }
            }
        }
        
        func contains(_ key: Key) -> Bool {
            switch self.focus {
            case .file:
                guard let index = key.intValue else { return false }
                return self.decoder.source.contains(rowIndex: index)
            case .row:
                if let index = key.intValue {
                    return index >= 0 && index < self.decoder.source.numFields
                } else if let headers = self.decoder.source.headers {
                    return headers.contains(key.stringValue)
                } else { return false }
            }
        }
    }
}

extension ShadowDecoder.KeyedContainer {
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
        switch self.focus {
        case .file:
            guard let rowIndex = key.intValue else { throw DecodingError.invalidRowKey(codingPath: self.codingPath + [key]) }
            let decoder = self.decoder.duplicate(appendingKey: DecodingKey(rowIndex))
            return KeyedDecodingContainer(ShadowDecoder.KeyedContainer<NestedKey>(unsafeDecoder: decoder, rowIndex: rowIndex))
        case .row: throw DecodingError.invalidContainerRequest(codingPath: self.codingPath)
        }
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        switch self.focus {
        case .file:
            guard let rowIndex = key.intValue else { throw DecodingError.invalidRowKey(codingPath: self.codingPath + [key]) }
            let decoder = self.decoder.duplicate(appendingKey: DecodingKey(rowIndex))
            return ShadowDecoder.UnkeyedContainer(unsafeDecoder: decoder, rowIndex: rowIndex)
        case .row: throw DecodingError.invalidContainerRequest(codingPath: self.codingPath)
        }
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        switch self.focus {
        case .file:
            guard let rowIndex = key.intValue else { throw DecodingError.invalidRowKey(codingPath: self.codingPath + [key]) }
            return self.decoder.duplicate(appendingKey: DecodingKey(rowIndex))
        case .row: throw DecodingError.invalidContainerRequest(codingPath: self.codingPath)
        }
    }
    
    func superDecoder() throws -> Decoder {
        switch self.focus {
        case .file: return self.decoder.duplicate(appendingKey: DecodingKey(0))
        case .row: throw DecodingError.invalidContainerRequest(codingPath: self.codingPath)
        }
    }
}

extension ShadowDecoder.KeyedContainer {
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        try self.fieldContainer(forKey: key).decode(String.self)
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        try self.fieldContainer(forKey: key).decodeNil()
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        try self.fieldContainer(forKey: key).decode(Bool.self)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        try self.fieldContainer(forKey: key).decode(Int.self)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        try self.fieldContainer(forKey: key).decode(Int8.self)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        try self.fieldContainer(forKey: key).decode(Int16.self)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        try self.fieldContainer(forKey: key).decode(Int32.self)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        try self.fieldContainer(forKey: key).decode(Int64.self)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        try self.fieldContainer(forKey: key).decode(UInt.self)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        try self.fieldContainer(forKey: key).decode(UInt8.self)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        try self.fieldContainer(forKey: key).decode(UInt16.self)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        try self.fieldContainer(forKey: key).decode(UInt32.self)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        try self.fieldContainer(forKey: key).decode(UInt64.self)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        try self.fieldContainer(forKey: key).decode(Float.self)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        try self.fieldContainer(forKey: key).decode(Double.self)
    }
    
    func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T:Decodable {
        if T.self == Date.self {
            return try self.fieldContainer(forKey: key).decode(Date.self) as! T
        } else if T.self == Data.self {
            return try self.fieldContainer(forKey: key).decode(Data.self) as! T
        } else if T.self == Decimal.self {
            return try self.fieldContainer(forKey: key).decode(Decimal.self) as! T
        } else if T.self == URL.self {
            return try self.fieldContainer(forKey: key).decode(URL.self) as! T
        } else {
            return try T(from: self.decoder.duplicate(appendingKey: key))
        }
    }
}

extension ShadowDecoder.KeyedContainer {
    func decodeIfPresent(_ type: String.Type, forKey key: Key) throws -> String? {
        try? self.decode(String.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: Bool.Type, forKey key: Key) throws -> Bool? {
        try? self.decode(Bool.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: Int.Type, forKey key: Key) throws -> Int? {
        try? self.decode(Int.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: Int8.Type, forKey key: Key) throws -> Int8? {
        try? self.decode(Int8.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: Int16.Type, forKey key: Key) throws -> Int16? {
        try? self.decode(Int16.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: Int32.Type, forKey key: Key) throws -> Int32? {
        try? self.decode(Int32.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: Int64.Type, forKey key: Key) throws -> Int64? {
        try? self.decode(Int64.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: UInt.Type, forKey key: Key) throws -> UInt? {
        try? self.decode(UInt.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: UInt8.Type, forKey key: Key) throws -> UInt8? {
        try? self.decode(UInt8.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: UInt16.Type, forKey key: Key) throws -> UInt16? {
        try? self.decode(UInt16.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: UInt32.Type, forKey key: Key) throws -> UInt32? {
        try? self.decode(UInt32.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: UInt64.Type, forKey key: Key) throws -> UInt64? {
        try? self.decode(UInt64.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: Float.Type, forKey key: Key) throws -> Float? {
        try? self.decode(Float.self, forKey: key)
    }
    
    func decodeIfPresent(_ type: Double.Type, forKey key: Key) throws -> Double? {
        try? self.decode(Double.self, forKey: key)
    }
    
    func decodeIfPresent<T>(_ type: T.Type, forKey key: Key) throws -> T? where T:Decodable {
        try? self.decode(T.self, forKey: key)
    }
}

extension ShadowDecoder.KeyedContainer {
    /// CSV keyed container focus (i.e. where the container is able to operate on).
    private enum Focus {
        /// The container represents the whole CSV file and each decoding operation outputs a row/record.
        case file
        /// The container represents a CSV row and each decoding operation outputs a field.
        case row(Int)
    }
    
    /// Returns a single value container to decode a single field within a row.
    /// - parameter key: The coding key under which the `String` value is located.
    /// - returns: The single value container holding the field decoding functionality.
    private func fieldContainer(forKey key: Key) throws -> ShadowDecoder.SingleValueContainer {
        let index: (row: Int, field: Int)
        let decoder: ShadowDecoder
        
        switch self.focus {
        case .row(let rowIndex):
            index = (rowIndex, try self.decoder.source.fieldIndex(forKey: key, codingPath: self.codingPath))
            decoder = self.decoder.duplicate(appendingKey: DecodingKey(index.field))
        case .file:
            guard let rowIndex = key.intValue else {
                throw DecodingError.invalidRowKey(codingPath: self.codingPath + [key])
            }
            // Values are only allowed to be decoded directly from a nested container in "file level" if the CSV rows have a single column.
            guard self.decoder.source.numFields == 1 else {
                throw DecodingError.invalidNestedRequired(codingPath: self.codingPath)
            }
            
            index = (rowIndex, 0)
            decoder = self.decoder.duplicate(appendingKeys: DecodingKey(index.row), DecodingKey(index.field))
        }
        
        return .init(unsafeDecoder: decoder, rowIndex: index.row, fieldIndex: index.field)
    }
}
