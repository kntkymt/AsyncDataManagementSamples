import SwiftUI

@main
struct AsyncDataManagementSamplesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    for await _ in NotificationCenter.default.notifications(named: .deviceDidShakeNotification) {
                        await API.throwError.set(!API.throwError.value)
                    }
                }
        }
    }
}

extension NSNotification.Name {
    public static let deviceDidShakeNotification = NSNotification.Name("DeviceDidShakeNotification")
}

extension UIWindow {
    open override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        super.motionEnded(motion, with: event)
        NotificationCenter.default.post(name: .deviceDidShakeNotification, object: event)
    }
}

