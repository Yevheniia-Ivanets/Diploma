import SwiftData

@Model
final class UserProfile {
    var name: String
    var weight: Double
    var height: Double
    var age: Int

    init(name: String = "", weight: Double = 70, height: Double = 175, age: Int = 25) {
        self.name = name
        self.weight = weight
        self.height = height
        self.age = age
    }
}
