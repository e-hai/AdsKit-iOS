import Foundation

public struct AdsPaidEvent: Sendable, Equatable {
    public let valueMicros: Int64
    public let currencyCode: String
    public let precision: Int

    public init(valueMicros: Int64 = 0, currencyCode: String = "USD", precision: Int = 0) {
        self.valueMicros = valueMicros
        self.currencyCode = currencyCode
        self.precision = precision
    }
}
