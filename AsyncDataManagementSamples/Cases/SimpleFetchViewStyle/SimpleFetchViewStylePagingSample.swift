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

    var isPagingFailure: Bool {
        if case .pagingFailure = self {
            return true
        }

        return false
    }

    public var value: V? {
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

private struct PagingList<V, Success: View>: View {

    // MARK: - Property

    @State private var dataState: PagingDataState<[V], any Error> = .idle

    private var fetchInitial: () async throws -> [V]
    private var fetchMore: (_ lastItem: V) async throws -> [V]
    private var success: (_ values: [V]) -> Success

    // MARK: - Initializer

    init(
        success: @escaping (_ values: [V]) -> Success,
        fetchInitial: @escaping () async throws -> [V],
        fetchMore: @escaping (_ lastItem: V) async throws -> [V]
    ) {
        self.success = success
        self.fetchInitial = fetchInitial
        self.fetchMore = fetchMore
    }

    // MARK: - Body

    var body: some View {
        List {
            switch dataState {
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

                    if dataState.isPagingFailure {
                        ErrorStateView {
                            Task {
                                await loadMore()
                            }
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                Task {
                                    await loadMore()
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
            if dataState.isInitialLoading {
                ProgressView()
            }
        }
        .task {
            await loadInitial()
        }
        .refreshable {
            await loadInitial()
        }
        .onChange(of: dataState.isFailure) { isFailure in
            guard isFailure, let error = dataState.error else { return }
            MessageBanner.showError("エラーが発生しました", with: error.localizedDescription)
        }
    }

    // MARK: - Private

    private func loadInitial() async {
        if dataState.isLoading || dataState.isPaging { return }
        dataState.startLoading()

        do {
            dataState = .success(try await fetchInitial())
        } catch {
            dataState = dataState.value.map { .reLoadingFailure($0, error) } ?? .loadingFailure(error)
        }
    }

    private func loadMore() async {
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

struct SimpleFetchViewStylePagingSample: View {

    // MARK: - Body

    var body: some View {
        PagingList(
            success: listContent,
            fetchInitial: { try await API.getPosts(minId: 0, count: 30) },
            fetchMore: { try await API.getPosts(minId: $0.id + 1, count: 30) }
        )
    }

    func listContent(posts: [Post]) -> some View {
        ForEach(posts) { post in
            Text(post.title)
        }
    }
}
