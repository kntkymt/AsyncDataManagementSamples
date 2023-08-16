import SwiftUI

private enum DataState<V, E: Error> {
    case idle
    case loading
    case success(V)
    case failure(E)
}

extension DataState {
    var isLoading: Bool {
        if case .loading = self {
            return true
        }

        return false
    }
}

struct Case1_Before: View {

    // MARK: - Property

    @State private var dataState: DataState<User, any Error> = .idle

    // MARK: - Body

    var body: some View {
        List {
            switch dataState {
            case .idle, .loading:
                EmptyView()

            case .success(let value):
                content(user: value)

            case .failure:
                ErrorStateView()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if dataState.isLoading {
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
        dataState = .loading

        do {
            dataState = .success(try await API.getUser())
        } catch {
            dataState = .failure(error)
        }
    }
}
