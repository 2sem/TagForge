import Combine
import CoreData

extension NSPersistentCloudKitContainer {
    /// A publisher that emits CloudKit container events decoded from
    /// `NSPersistentCloudKitContainer.eventChangedNotification`.
    static var eventChangedPublisher: AnyPublisher<NSPersistentCloudKitContainer.Event, Never> {
        NotificationCenter.default
            .publisher(for: NSPersistentCloudKitContainer.eventChangedNotification)
            .compactMap {
                $0.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey]
                    as? NSPersistentCloudKitContainer.Event
            }
            .eraseToAnyPublisher()
    }
}
