import SwiftUI
private enum PagingDataState<V, E: Error> {
    case idle

    case initialLoading
    case retryLoading(E)
    case reLoading(V)

    case paging(V)

    case success(V)
    case loadingFailure(E)
    case reLoadingFailure(V, E)
    case pagingFailure(V, E)
}

extension PagingDataState {
    mutating func startLoading() {
        switch self {
        case .idle:
            self = .initialLoading

        case .loadingFailure(let error):
            self = .retryLoading(error)

        case .success(let value),
                .reLoadingFailure(let value, _),
                .pagingFailure(let value, _):
            self = .reLoading(value)

        case .initialLoading,
                .retryLoading,
                .reLoading,
                .paging:
            return
        }
    }

    mutating func startPaging() {
        switch self {
        case .success(let value),
                .reLoadingFailure(let value, _),
                .pagingFailure(let value, _):
            self = .paging(value)

        case .idle,
                .loadingFailure,
                .initialLoading,
                .retryLoading,
                .reLoading,
                .paging:
            return
        }
    }

    var isLoading: Bool {
        switch self {
        case .initialLoading,
                .retryLoading,
                .reLoading:

            return true

        default:
            return false
        }
    }

    var isPaging: Bool {
        if case .paging = self {
            return true
        }

        return false
    }

    var isInitialLoading: Bool {
        if case .initialLoading = self {
            return true
        }

        return false
    }

    var isPagingFailure: Bool {
        if case .pagingFailure = self {
            return true
        }

        return false
    }

    var isFailure: Bool {
        switch self {
        case .loadingFailure,
                .reLoadingFailure,
                .pagingFailure:
            return true

        default:
            return false
        }
    }

    var value: V? {
        switch self {
        case .reLoading(let value),
                .paging(let value),
                .success(let value),
                .reLoadingFailure(let value, _),
                .pagingFailure(let value, _):
            return value

        default:
            return nil
        }
    }

    var error: E? {
        switch self {
        case .retryLoading(let error),
                .loadingFailure(let error),
                .reLoadingFailure(_, let error),
                .pagingFailure(_, let error):
            return error

        default:
            return nil
        }
    }
}

@MainActor
private final class LoadingContentViewStore<V>: ObservableObject {

    // MARK: - Property

    @Published private(set) var dataState: PagingDataState<[V], any Error> = .idle

    private var fetchInitial: () async throws -> [V]
    private var fetchMore: (_ lastItem: V) async throws -> [V]

    // MARK: - Initializer

    init(fetchInitial: @escaping () async throws -> [V], fetchMore: @escaping (_ lastItem: V) async throws -> [V]) {
        self.fetchInitial = fetchInitial
        self.fetchMore = fetchMore
    }

    // MARK: - Internal

    func loadInitial() async {
        if dataState.isLoading || dataState.isPaging { return }
        dataState.startLoading()

        do {
            dataState = .success(try await fetchInitial())
        } catch {
            dataState = dataState.value.map { .reLoadingFailure($0, error) } ?? .loadingFailure(error)
        }
    }

    func loadMore() async {
        if dataState.isLoading || dataState.isPaging { return }
        guard let value = dataState.value, let lastItem = value.last else { return }
        dataState.startPaging()

        do {
            let moreValue = try await fetchMore(lastItem)
            dataState = .success(value + moreValue)
        } catch {
            dataState = .pagingFailure(value, error)
        }
    }
}

private struct PagingList<V, Success: View>: View {

    // MARK: - Property

    @StateObject private var viewStore: LoadingContentViewStore<V>

    private var success: (_ values: [V]) -> Success

    // MARK: - Initializer

    init(
        viewStore: LoadingContentViewStore<V>,
        success: @escaping (_ values: [V]) -> Success
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

            case .reLoading(let value),
                    .paging(let value),
                    .success(let value),
                    .reLoadingFailure(let value, _),
                    .pagingFailure(let value, _):
                if value.isEmpty {
                    Text("投稿はありません")
                        .font(.title3)
                        .fontWeight(.medium)
                } else {
                    success(value)

                    if viewStore.dataState.isPagingFailure {
                        ErrorStateView {
                            Task {
                                await viewStore.loadMore()
                            }
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                Task {
                                    await viewStore.loadMore()
                                }
                            }
                    }
                }

            case .retryLoading,
                    .loadingFailure:
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
            await viewStore.loadInitial()
        }
    }
}

struct FetchViewStylePagingSample: View {

    // MARK: - Property

    @StateObject private var viewStore: LoadingContentViewStore<Post> = .init(
        fetchInitial: { try await API.getPosts(minId: 0, count: 30) },
        fetchMore: { try await API.getPosts(minId: $0.id + 1, count: 30) }
    )

    // MARK: - Body

    var body: some View {
        PagingList(viewStore: viewStore, success: listContent)
            .task {
                await viewStore.loadInitial()
            }
            .onChange(of: viewStore.dataState.isFailure) { bool in
                guard bool, let error = viewStore.dataState.error else { return }
                MessageBanner.showError("エラーが発生しました", with: error.localizedDescription)
            }
    }

    func listContent(posts: [Post]) -> some View {
        ForEach(posts) { post in
            Text(post.title)
        }
    }
}
