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
        if case .failure = self {
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

    var error: E? {
        if case .failure(let error) = self {
            return error
        }

        return nil
    }
}

private struct LoadingListContent<V, Success: View>: View {

    // MARK: - Property

    @State private var dataState: DataState<V, any Error> = .idle

    private var fetch: () async throws -> V

    private var success: (_ value: V) -> Success

    // MARK: - Initializer

    init(
        fetch: @escaping () async throws -> V,
        success: @escaping (_ value: V) -> Success
    ) {
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
                    .reLoading(let value):
                success(value)

            case .failure,
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
        .onChange(of: dataState.isFailure) { isFailure in
            guard isFailure, let error = dataState.error else { return }
            MessageBanner.showError("エラーが発生しました", with: error.localizedDescription)
        }
    }

    // MARK: - Private

    private func load() async {
        if dataState.isLoading { return }
        dataState.startLoading()

        do {
            dataState = .success(try await fetch())
        } catch {
            dataState = .failure(error)
        }
    }
}

struct SimpleFetchViewStyleSample: View {

    var body: some View {
        LoadingListContent(fetch: API.getUser, success: content)
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
