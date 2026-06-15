//
//  NotificationManager.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/14/26.
//

import Foundation
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter` for requesting permission and applying a
/// `NotificationPlanner.Plan`.
class NotificationManager {

    static let dailyReminderIdentifier = "dailyLoggingReminder"
    static let streakAtRiskIdentifier = "streakAtRisk"

    private let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    /// Cancels any pending "habit loop" notifications and schedules new ones based on `plan`.
    func apply(_ plan: NotificationPlanner.Plan) {
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.dailyReminderIdentifier,
            Self.streakAtRiskIdentifier,
        ])

        if let fireDate = plan.dailyReminderFireDate {
            schedule(
                identifier: Self.dailyReminderIdentifier,
                title: "Don't forget to log today!",
                body: "You haven't logged anything since lunch. Add what you've eaten to keep your nutrient tracking up to date.",
                fireDate: fireDate
            )
        }

        if let fireDate = plan.streakAtRiskFireDate {
            schedule(
                identifier: Self.streakAtRiskIdentifier,
                title: "Don't break your streak!",
                body: "You're on a \(plan.streakCount)-day logging streak. Log something before midnight to keep it going.",
                fireDate: fireDate
            )
        }
    }

    private func schedule(identifier: String, title: String, body: String, fireDate: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }
}
