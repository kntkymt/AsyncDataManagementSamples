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

    var isReLoading: Bool {
        if case .reLoading = self {
            return true
        }

        return false
    }

    var isRetryLoading: Bool {
        if case .retryLoading = self {
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

    var isLoadingFailure: Bool {
        if case .loadingFailure = self {
            return true
        }

        return false
    }

    var isReLoadingFailure: Bool {
        if case .reLoadingFailure = self {
            return true
        }

        return false
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

@MainActor
private final class LoadingContentViewStore<V>: ObservableObject {

    // MARK: - Property

    @Published private(set) var dataState: DataState<V, any Error> = .idle

    private var fetch: () async throws -> V

    // MARK: - Initializer

    init(fetch: @escaping () async throws -> V) {
        self.fetch = fetch
    }

    // MARK: - Internal

    func load() async {
        if dataState.isLoading { return }

        dataState.startLoading()
        do {
            dataState = .success(try await fetch())
        } catch {
            dataState = dataState.value.map { .reLoadingFailure($0, error) } ?? .loadingFailure(error)
        }
    }
}

private struct LoadingListContent<V, Success: View>: View {

    // MARK: - Property

    @StateObject private var viewStore: LoadingContentViewStore<V>

    private var success: (_ value: V) -> Success

    // MARK: - Initializer

    init(
        viewStore: LoadingContentViewStore<V>,
        success: @escaping (_ value: V) -> Success
    ) {
        self._viewStore = .init(wrappedValue: viewStore)
        self.success = success
    }

    // MARK: - Body

    var body: some View {
        List {
            switch viewStore.dataState {
            case .idle, .initialLoading:
                EmptyView()

            case .success(let value),
                    .reLoading(let value),
                    .reLoadingFailure(let value, _):
                success(value)

            case .loadingFailure,
                    .retryLoading:
                ErrorStateView()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if viewStore.dataState.isInitialLoading {
                ProgressView()
            }
        }
        .refreshable {
            await viewStore.load()
        }
    }
}

struct FetchViewStyleSample: View {

    // MARK: - Property

    @StateObject private var viewStore: LoadingContentViewStore<User> = .init(fetch: API.getUser)

    // MARK: - Body

    var body: some View {
        LoadingListContent(viewStore: viewStore, success: content)
            .task {
                await viewStore.load()
            }
            .onChange(of: viewStore.dataState.isFailure) { isFailure in
                guard isFailure, let error = viewStore.dataState.error else { return }
                MessageBanner.showError("エラーが発生しました", with: error.localizedDescription)
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
}
