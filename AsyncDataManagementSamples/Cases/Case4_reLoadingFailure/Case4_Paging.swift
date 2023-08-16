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

struct Case4_Paging: View {

    // MARK: - Property

    @State private var dataState: PagingDataState<[Post], any Error> = .idle

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
                    listContent(posts: value)

                    if dataState.isPagingFailure {
                        ErrorStateView {
                            Task {
                                await fetchMore()
                            }
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                Task {
                                    await fetchMore()
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
        .refreshable {
            await fetchInitial()
        }
        .task {
            await fetchInitial()
        }
        .onChange(of: dataState.isFailure) { isFailure in
            guard isFailure, let error = dataState.error else { return }
            MessageBanner.showError("エラーが発生しました", with: error.localizedDescription)
        }
    }

    func listContent(posts: [Post]) -> some View {
        ForEach(posts) { post in
            Text(post.title)
        }
    }

    // MARK: - Private

    private func fetchInitial() async {
        if dataState.isLoading || dataState.isPaging { return }
        dataState.startLoading()

        do {
            dataState = .success(try await API.getPosts(minId: 0, count: 30))
        } catch {
            dataState = dataState.value.map { .reLoadingFailure($0, error) } ?? .loadingFailure(error)
        }
    }

    private func fetchMore() async {
        if dataState.isLoading || dataState.isPaging { return }
        guard let users = dataState.value, let minId = users.last?.id else { return }
        dataState.startPaging()

        do {
            let newUsers = try await API.getPosts(minId: minId + 1, count: 30)
            dataState = .success(users + newUsers)
        } catch {
            dataState = .pagingFailure(users, error)
        }
    }
}
