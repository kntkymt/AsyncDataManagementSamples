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

private struct LoadingContent<V, Content: View>: View {

    // MARK: - Property

    private let dataState: DataState<V, any Error>
    private let content: (_ value: V) -> Content
    private let onRefresh: (() -> Void)?

    // MARK: - Initializer

    init(
        dataState: DataState<V, any Error>,
        content: @escaping (_ value: V) -> Content,
        onRefresh: (() -> Void)? = nil
    ) {
        self.dataState = dataState
        self.content = content
        self.onRefresh = onRefresh
    }

    // MARK: - Body

    var body: some View {
        switch dataState {
        case .idle,
                .initialLoading:
            EmptyView()

        case .success(let value),
                .reLoading(let value),
                .reLoadingFailure(let value, _):
            content(value)

        case .loadingFailure,
                .retryLoading:
            ErrorStateView(action: onRefresh)
                .frame(height: 300)
                .frame(maxWidth: .infinity)
        }
    }
}

struct SwitchViewStyleSample: View {

    // MARK: - Property

    @State private var dataState: DataState<User, any Error> = .idle

    // MARK: - Body

    var body: some View {
        List {
            LoadingContent(dataState: dataState, content: content)
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
            dataState = .success(try await API.getUser())
        } catch {
            dataState = dataState.value.map { .reLoadingFailure($0, error) } ?? .loadingFailure(error)
        }
    }

    private func content(user: User) -> some View {
        Group {
            LabeledContent("ID", value: user.id)
            LabeledContent("Name", value: user.name)
            LabeledContent("Email", value: user.email)
            LabeledContent("Location", value: user.location)
        }
    }
}
