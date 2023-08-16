import SwiftUI

private enum DataState<V, E: Error> {
    case idle
    case initialLoading
    case reLoading(V)
    case retryLoading(E)
    case success(V)
    case failure(E)
}

extension DataState {
    mutating func startLoading() {
        switch self {
        case .idle:
            self = .initialLoading
        case .success(let value):
            self = .reLoading(value)
        case .failure(let error):
            self = .retryLoading(error)
        default:
            return
        }
    }

    var isLoading: Bool {
        switch self {
        case .initialLoading,
                .reLoading,
                .retryLoading:
            return true

        default:
            return false
        }
    }

    var isInitialLoading: Bool {
        if case .initialLoading = self {
            return true
        }

        return false
    }

    var value: V? {
        switch self {
        case .reLoading(let value),
                .success(let value):
            return value

        default:
            return nil
        }
    }
}

struct CaseEX: View {

    // MARK: - Property

    @State private var dataState: DataState<User, any Error> = .idle

    // MARK: - Body

    var body: some View {
        List {
            switch dataState {
            case .idle,
                    .initialLoading,
                    .success,
                    .reLoading:

                let value = dataState.value ?? .stub
                content(user: value)
                    .redacted(reason: dataState.value == nil ? .placeholder : [])

            case .failure,
                    .retryLoading:
                ErrorStateView()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await fetchUser()
        }
        .refreshable {
            await fetchUser()
        }
    }

    func content(user: User) -> some View {
        Group {
            HStack {
                Text("ID")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .unredacted()

                Text(user.id)
            }

            HStack {
                Text("Name")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .unredacted()

                Text(user.name)
            }

            HStack {
                Text("Email")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .unredacted()

                Text(user.email)
                    .fixedSize(horizontal: true, vertical: true)
            }

            HStack {
                Text("Location")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .unredacted()

                Text(user.location)
            }
        }
    }

    // MARK: - Private

    private func fetchUser() async {
        if dataState.isLoading { return }
        dataState.startLoading()

        do {
            dataState = .success(try await API.getUser())
        } catch {
            dataState = .failure(error)
        }
    }
}

struct CaseEX_NG: View {

    // MARK: - Property

    @State private var dataState: DataState<User, any Error> = .idle

    // MARK: - Body

    var body: some View {
        List {
            switch dataState {
            case .idle, .initialLoading:

                content(user: .stub)
                    .redacted(reason: .placeholder)

            case .success(let value),
                    .reLoading(let value):
                content(user: value)

            case .failure,
                    .retryLoading:
                ErrorStateView()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .task {
            await fetchUser()
        }
        .refreshable {
            await fetchUser()
        }
    }

    func content(user: User) -> some View {
        Group {
            HStack {
                Text("ID")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .unredacted()

                Text(user.id)
            }

            HStack {
                Text("Name")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .unredacted()

                Text(user.name)
            }

            HStack {
                Text("Email")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .unredacted()

                Text(user.email)
                    .fixedSize(horizontal: true, vertical: true)
            }

            HStack {
                Text("Location")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .unredacted()

                Text(user.location)
            }
        }
    }

    // MARK: - Private

    private func fetchUser() async {
        if dataState.isLoading { return }
        dataState.startLoading()

        do {
            dataState = .success(try await API.getUser())
        } catch {
            dataState = .failure(error)
        }
    }
}
