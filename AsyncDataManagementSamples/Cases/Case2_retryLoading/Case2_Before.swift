import SwiftUI

private enum DataState<V, E: Error> {
    case idle
    case initialLoading
    case reLoading(V)
    case success(V)
    case failure(E)
}

extension DataState {
    mutating func startLoading() {
        if case .success(let value) = self {
            self = .reLoading(value)
        } else {
            self = .initialLoading
        }
    }

    var isLoading: Bool {
        switch self {
        case .initialLoading,
                .reLoading:
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
}

struct Case2_Before: View {

    // MARK: - Property

    @State private var dataState: DataState<User, any Error> = .idle

    // MARK: - Body

    var body: some View {
        List {
            switch dataState {
            case .idle,
                    .initialLoading:
                EmptyView()

            case .success(let value),
                    .reLoading(let value):
                content(user: value)

            case .failure:
                ErrorStateView()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if dataState.isInitialLoading {
                ProgressView()
            }
        }
        .task {
            await fetchUser()
        }
        .refreshable {
            await fetchUser()
        }
    }

    func fetchUser() async {
        if dataState.isLoading { return }
        dataState.startLoading()

        do {
            dataState = .success(try await API.getUser())
        } catch {
            dataState = .failure(error)
        }
    }

    // MARK: - Private

    private func content(user: User) -> some View {
        Group {
            LabeledContent("ID", value: user.id)
            LabeledContent("Name", value: user.name)
            LabeledContent("Email", value: user.email)
            LabeledContent("Location", value: user.location)
        }
    }
}
