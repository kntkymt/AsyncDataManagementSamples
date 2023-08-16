import SwiftUI

struct Case0_Before: View {

    // MARK: - Property

    @State private var data: User?
    @State private var error: (any Error)?
    @State private var isLoading = false

    // MARK: - Body

    var body: some View {
        List {
            if isLoading {
                EmptyView()
            } else {
                if let data {
                    content(user: data)
                } else if error != nil {
                    ErrorStateView {
                        Task {
                            await fetchUser()
                        }
                    }
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if isLoading {
                ProgressView()
            }
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
        if isLoading { return }
        isLoading = true
        data = nil
        error = nil

        do {
            data = try await API.getUser()
        } catch {
            self.error = error
        }

        isLoading = false
    }
}
