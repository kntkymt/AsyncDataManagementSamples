import SwiftUI

private enum DataState<V, E: Error> {
    case idle
    case loading(V?)
    case success(V)
    case failure(E)
}

extension DataState {
    mutating func startLoading() {
        switch self {
        case .idle, .failure:
            self = .loading(nil)
        case .success(let value):
            self = .loading(value)
        default:
            return
        }
    }

    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }

    var isInitialLoading: Bool {
        if case .loading(let value) = self {
            return value == nil
        }

        return false
    }
}

struct Case1_Alt: View {

    // MARK: - Property

    @State private var dataState: DataState<User, any Error> = .idle

    // MARK: - Body

    var body: some View {
        List {
            switch dataState {
            case .idle, .loading(nil):
                EmptyView()

            case .success(let value),
                    .loading(let value?):
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
        .refreshable {
            await fetchUser()
        }
        .task {
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
