
struct AppVersion: Sendable, Equatable, Comparable {
    private let components: [Int]

    init(major: Int, minor: Int = 0, patch: Int = 0) {
        self.init(normalizing: [major, minor, patch])
    }

    init(_ value: String) throws {
        let parts = value.split(separator: ".", omittingEmptySubsequences: false)
        guard !parts.isEmpty else { throw CardError.invalidResponse }
        var numbers: [Int] = []
        for part in parts {
            guard !part.isEmpty, part.utf8.allSatisfy({ (48...57).contains($0) }),
                  let number = Int(part) else { throw CardError.invalidResponse }
            numbers.append(number)
        }
        self.init(normalizing: numbers)
    }

    private init(normalizing numbers: [Int]) {
        var numbers = numbers
        while numbers.count > 1, numbers.last == 0 { numbers.removeLast() }
        components = numbers
    }

    static func < (lhs: Self, rhs: Self) -> Bool {
        for index in 0..<max(lhs.components.count, rhs.components.count) {
            let left = index < lhs.components.count ? lhs.components[index] : 0
            let right = index < rhs.components.count ? rhs.components[index] : 0
            if left != right { return left < right }
        }
        return false
    }
}
