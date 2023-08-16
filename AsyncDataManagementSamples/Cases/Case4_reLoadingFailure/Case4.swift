import SwiftUI

private enum DataState<V, E: Error> {
    case idle

    case initialLoading
    case reLoading(V)
    case retryLoading(E)

    case success(V)
    case loadingFailure(E)
    case reLoadingFailure(V, E)
}
extension DataState {
    mutating func startLoading() {
        switch self {
        case .idle:
            self = .initialLoading
        case .success(let value),
                .reLoadingFailure(let value, _):
            self = .reLoading(value)
        case .loadingFailure(let error):
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

    var isFailure: Bool {
        switch self {
        case .loadingFailure,
                .reLoadingFailure:
            return true

        default:
            return false
        }
    }

    var error: (any Error)? {
        switch self {
        case .retryLoading(let error),
                .loadingFailure(let error),
                .reLoadingFailure(_, let error):
            return error

        default:
            return nil
        }
    }

    var value: V? {
        switch self {
        case .reLoading(let value),
                .success(let value),
                .reLoadingFailure(let value, _):
            return value

        default:
            return nil
        }
    }
}

struct Case4: View {

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
                    .reLoading(let value),
                    .reLoadingFailure(let value, _):
                content(user: value)

            case .loadingFailure,
                    .retryLoading:
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
        .onChange(of: dataState.isFailure) { isFailure in
            guard isFailure, let error = dataState.error else { return }
            MessageBanner.showError("エラーが発生しました", with: error.localizedDescription)
        }
        .task {
            await fetchUser()
        }
        .refreshable {
            await fetchUser()
        }
    }

    func content(user: User) -> some View {
        Group {
            LabeledContent("ID", value: user.id)
            LabeledContent("Name", value: user.name)
            LabeledContent("Email", value: user.email)
            LabeledContent("Location", value: user.location)
        }
    }

    // MARK: - Private

    private func fetchUser() async {
        if dataState.isLoading { return }
        dataState.startLoading()

        do {
            dataState = .success(try await API.getUser())
        } catch {
            dataState = dataState.value.map { .reLoadingFailure($0, error) } ?? .loadingFailure(error)
        }
    }
}
