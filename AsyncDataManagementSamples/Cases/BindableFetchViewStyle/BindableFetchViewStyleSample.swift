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

private struct LoadingListContent<V, Success: View>: View {

    // MARK: - Property

    @Binding private var dataState: DataState<V, any Error>
    private var fetch: () async throws -> V

    private var success: (V) -> Success

    // MARK: - Initializer

    init(
        dataState: Binding<DataState<V, any Error>>,
        fetch: @escaping () async throws -> V,
        success: @escaping (_ value: V) -> Success
    ) {
        self._dataState = dataState
        self.fetch = fetch
        self.success = success
    }

    // MARK: - Body

    var body: some View {
        List {
            switch dataState {
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
            if dataState.isInitialLoading {
                ProgressView()
            }
        }
        .refreshable {
            await load()
        }
        .task {
            await load()
        }
    }

    // MARK: - Private

    private func load() async {
        if dataState.isLoading { return }
        dataState.startLoading()

        do {
            dataState = .success(try await fetch())
        } catch {
            dataState = dataState.value.map { .reLoadingFailure($0, error) } ?? .loadingFailure(error)
        }
    }
}

struct BindableFetchViewStyleSample: View {

    // MARK: - Property

    @State private var dataState: DataState<User, any Error> = .idle

    // MARK: - Body

    var body: some View {
        LoadingListContent(dataState: $dataState, fetch: API.getUser, success: content)
            .onChange(of: dataState.isFailure) { isFailure in
                guard isFailure, let error = dataState.error else { return }
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
