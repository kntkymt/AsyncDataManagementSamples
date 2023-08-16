import SwiftUI

struct ErrorStateView: View {

    // MARK: - Property

    let action: (() -> Void)?

    // MARK: - Initializer

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        VStack {
            Text("エラーが発生しました")
                .fontWeight(.medium)
                .font(.title3)

            if let action {
                Text("再読み込み")
                    .font(.title3)
                    .foregroundColor(Color(.link))
                    .onTapGesture {
                        action()
                    }
            }
        }
    }
}
