import Foundation

struct User: Identifiable {
    var id: String
    var name: String
    var email: String
    var location: String
}

extension User {
    static var stub: User {
        User(id: "ユーザーID", name: "ユーザー名", email: "メールアドレス", location: "場所")
    }
}

struct Post: Identifiable {
    var id: Int
    var title: String
}

extension Post {
    static var stubs: [Post] {
        [
            .init(id: 100000, title: "stub1"),
            .init(id: 100001, title: "stub2"),
            .init(id: 100002, title: "stub3"),
            .init(id: 100003, title: "stub4"),
            .init(id: 100004, title: "stub5"),
            .init(id: 100005, title: "stub6"),
            .init(id: 100006, title: "stub7"),
            .init(id: 100007, title: "stub8"),
            .init(id: 100008, title: "stub9"),
            .init(id: 100009, title: "stub10"),
        ]
    }
}

enum APIError: Error {
    case network
}

actor AtomicValue<V> {
    var value: V

    init(initialValue: V) {
        self.value = initialValue
    }

    func set(_ value: V) {
        self.value = value
    }
}

enum API {
    static var throwError: AtomicValue<Bool> = .init(initialValue: false)

    static func getUser() async throws -> User {
        try await Task.sleep(nanoseconds: UInt64(1 * 1_000_000_000))

        if await throwError.value {
            throw APIError.network
        }

        return User(id: "kntkymt", name: "kntk", email: "email@example.com", location: "Tokyo")
    }

    static func getPosts(minId: Int, count: Int) async throws -> [Post] {
        try await Task.sleep(nanoseconds: UInt64(1 * 1_000_000_000))

        if await throwError.value {
            throw APIError.network
        }

        return (0..<count).map { Post(id: minId + $0, title: "post \(minId + $0)") }
    }
}
