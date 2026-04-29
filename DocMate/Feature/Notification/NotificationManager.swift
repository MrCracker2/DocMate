//
//  NotificationManager.swift
//  DocMate
//
//  Created by Shashwat kumar on 27/04/26.
//

//
//  NotificationManager.swift
//  DocMate
//
//  Created by Shashwat kumar on 27/04/26.
//

import Foundation
import UserNotifications

class NotificationManager {

    static let shared = NotificationManager()

    private init() {}

    // MARK: - Ask Permission
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in

                if granted {
                    print("Notifications allowed")
                } else {
                    print("Notifications denied")
                }

                if let error = error {
                    print("Notification error:", error)
                }
            }
    }

    // MARK: - Real Expiry Reminder
    func scheduleExpiryReminder(for document: Document) {

        guard let dueDate = document.dueDate else { return }

        let calendar = Calendar.current
        let now = Date()

        // Reminder days before expiry
        let reminderDays = [30, 7, 1]

        for day in reminderDays {

            guard let reminderDate = calendar.date(
                byAdding: .day,
                value: -day,
                to: dueDate
            ) else { continue }

            // Skip old dates
            if reminderDate <= now { continue }

            let content = UNMutableNotificationContent()
            content.title = "Document Expiring Soon"
            content.body = "\(document.name) expires in \(day) day\(day == 1 ? "" : "s")."
            content.sound = .default

            let components = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: reminderDate
            )

            let trigger = UNCalendarNotificationTrigger(
                dateMatching: components,
                repeats: false
            )

            let request = UNNotificationRequest(
                identifier: "\(document.id.uuidString)-\(day)",
                content: content,
                trigger: trigger
            )

            UNUserNotificationCenter.current().add(request)

            print("Reminder scheduled:", document.name, "-", day, "days before")
        }
    }

    // MARK: - Clear Pending Notifications
    func removeAll() {
        UNUserNotificationCenter.current()
            .removeAllPendingNotificationRequests()
    }
}




// MARK: tested only 
//import Foundation
//import UserNotifications
//
//class NotificationManager {
//
//    static let shared = NotificationManager()
//
//    private init() {}
//
//    func requestPermission() {
//        UNUserNotificationCenter.current()
//            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
//
//                if granted {
//                    print("✅ Notifications allowed")
//                } else {
//                    print("❌ Notifications denied")
//                }
//
//                if let error = error {
//                    print("Notification error:", error)
//                }
//            }
//    }
//
////    func scheduleExpiryReminder(for document: Document) {
////
////        guard let dueDate = document.dueDate else { return }
////
////        let calendar = Calendar.current
////
////        // Notify 7 days before expiry
////        guard let reminderDate = calendar.date(byAdding: .day, value: -7, to: dueDate) else { return }
////
////        if reminderDate < Date() { return }
////
////        let content = UNMutableNotificationContent()
////        content.title = "Document Expiring Soon"
////        content.body = "\(document.name) expires in 7 days."
////        content.sound = .default
////
////        _ = calendar.dateComponents(
////            [.year, .month, .day, .hour, .minute],
////            from: reminderDate
////        )
////
//////        let trigger = UNCalendarNotificationTrigger(
//////            dateMatching: components,
//////            repeats: false
//////        )
//////
//////        let request = UNNotificationRequest(
//////            identifier: document.id.uuidString,
//////            content: content,
//////            trigger: trigger
//////        )
//////
//////        UNUserNotificationCenter.current()
//////            .add(request)
////        let trigger = UNTimeIntervalNotificationTrigger(
////            timeInterval: 5,
////            repeats: false
////        )
////
////        let request = UNNotificationRequest(
////            identifier: document.id.uuidString,
////            content: content,
////            trigger: trigger
////        )
////
////        UNUserNotificationCenter.current().add(request)
////    }
//    func scheduleExpiryReminder(for document: Document) {
//
//        let content = UNMutableNotificationContent()
//        content.title = "Test Notification"
//        content.body = "\(document.name) working!"
//        content.sound = .default
//
//        let trigger = UNTimeIntervalNotificationTrigger(
//            timeInterval: 5,
//            repeats: false
//        )
//
//        let request = UNNotificationRequest(
//            identifier: UUID().uuidString,
//            content: content,
//            trigger: trigger
//        )
//
//        UNUserNotificationCenter.current().add(request)
//
//        print("Scheduled:", document.name)
//    }
//    func removeAll() {
//        UNUserNotificationCenter.current()
//            .removeAllPendingNotificationRequests()
//    }
//}
//
//
