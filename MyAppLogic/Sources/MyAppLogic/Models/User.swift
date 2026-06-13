import Foundation

/// Represents a user's physical profile used for workout personalisation.
public struct User: Sendable, Identifiable {
    public let id: UUID
    /// Body weight in kilograms.
    public var weight: Double
    /// Height in centimetres.
    public var height: Double
    /// Age in years.
    public var age: Int

    public init(id: UUID = UUID(), weight: Double, height: Double, age: Int) {
        self.id = id
        self.weight = weight
        self.height = height
        self.age = age
    }
}
