//
//  NotificationManager.swift
//  NStack
//
//  Created by Kasper Welner on 19/10/15.
//  Copyright © 2015 Nodes. All rights reserved.
//

import Foundation
import UIKit

public class AlertManager {

    public enum RateReminderResult: String {
        case Rate = "yes"
        case Later = "later"
        case Never = "no"
    }

    public enum AlertType {
        case updateAlert(title:String, text:String, dismissButtonText:String?, appStoreButtonText:String, completion:(_ didPressAppStore:Bool) -> Void)
        case whatsNewAlert(title: String, text: String, dismissButtonText: String, completion:() -> Void)
        case message(text: String, dismissButtonText: String, completion:() -> Void)
        case rateReminder(title:String, text: String, rateButtonText:String, laterButtonText:String, neverButtonText:String, completion:(_ result:RateReminderResult) -> Void)

        init(rateReminder: RateReminder, completion: @escaping (RateReminderResult) -> Void) {
            self = .rateReminder(title: rateReminder.title,
                                 text: rateReminder.body,
                                 rateButtonText: rateReminder.yesButtonTitle,
                                 laterButtonText: rateReminder.laterButtonTitle,
                                 neverButtonText: rateReminder.noButtonTitle,
                                 completion: completion)
        }
    }

    let repository: VersionsRepository

    var alertWindow = UIWindow(frame: UIScreen.main.bounds)

    public var alreadyShowingAlert: Bool {
        return !alertWindow.isHidden
    }

    // FIXME: Refactor

    public var showAlertBlock: (_ alertType: AlertType) -> Void = { alertType in
        guard !NStack.sharedInstance.alertManager.alreadyShowingAlert else {
            return
        }

        var header:String?
        var message:String?
        var actions = [UIAlertAction]()

        switch alertType {
        case let .updateAlert(title, text, dismissText, appStoreText, completion):
            header = title
            message = String(NSString(format: text as NSString))
            if let dismissText = dismissText {
                actions.append(UIAlertAction(title: dismissText, style: .default, handler: { action in
                    NStack.sharedInstance.alertManager.hideAlertWindow()
                    completion(false)
                }))
            }

            actions.append(UIAlertAction(title: appStoreText, style: .default, handler: { action in
                NStack.sharedInstance.alertManager.hideAlertWindow()
                completion(true)
            }))

        case let .whatsNewAlert(title, text, dismissButtonText, completion):
            header = title
            message = text
            actions.append(UIAlertAction(title: dismissButtonText, style: .cancel, handler: { action in
                NStack.sharedInstance.alertManager.hideAlertWindow()
                completion()
            }))

        case let .message(text, dismissButtonText, completion):
            message = text
            actions.append(UIAlertAction(title: dismissButtonText, style: .cancel, handler: { action in
                NStack.sharedInstance.alertManager.hideAlertWindow()
                completion()
            }))

        case let .rateReminder(title, text, rateButtonText, laterButtonText, neverButtonText, completion):
            header = title
            message = text
            actions.append(UIAlertAction(title: rateButtonText, style: .default, handler: { action in
                NStack.sharedInstance.alertManager.hideAlertWindow()
                completion(.Rate)
            }))
            actions.append(UIAlertAction(title: laterButtonText, style: .default, handler: { action in
                NStack.sharedInstance.alertManager.hideAlertWindow()
                completion(.Later)

            }))
            actions.append(UIAlertAction(title: neverButtonText, style: .cancel, handler: { action in
                NStack.sharedInstance.alertManager.hideAlertWindow()
                completion(.Never)
            }))
        }

        let alert = UIAlertController(title: header, message: message, preferredStyle: .alert)
        for action in actions {
            alert.addAction(action)
        }

        NStack.sharedInstance.alertManager.alertWindow.makeKeyAndVisible()
        NStack.sharedInstance.alertManager.alertWindow.rootViewController?.present(alert, animated: true, completion: nil)
    }

    // MARK: - Lifecyle -

    init(repository: VersionsRepository) {
        self.repository = repository
        self.alertWindow.windowLevel = UIWindowLevelAlert + 1
        self.alertWindow.rootViewController = UIViewController()
    }

    public func hideAlertWindow() {
        alertWindow.isHidden = true
    }

    internal func showUpdateAlert(newVersion version:Update.Version) {

        let appStoreCompletion = { (didPressAppStore:Bool) -> Void in
            self.repository.markNewerVersionAsSeen(version.lastId, appStoreButtonPressed: didPressAppStore)
            if didPressAppStore {
                if let link = version.link {
                    _ = UIApplication.safeSharedApplication()?.safeOpenURL(link)
                }
            }
        }

        let alertType: AlertType

        switch version.state {
        case .Force:
            alertType = AlertType.updateAlert(title: version.translations.title,
                                              text: version.translations.message,
                                              dismissButtonText: nil,
                                              appStoreButtonText: version.translations.positiveBtn,
                                              completion: appStoreCompletion)
        case .Remind:
            alertType = AlertType.updateAlert(title: version.translations.title,
                                              text: version.translations.message,
                                              dismissButtonText: version.translations.negativeBtn,
                                              appStoreButtonText: version.translations.positiveBtn,
                                              completion: appStoreCompletion)
        case .Disabled:
            return
        }

        self.showAlertBlock(alertType)
    }

    internal func showWhatsNewAlert(_ changeLog:Update.Changelog) {
        guard let translations = changeLog.translate else { return }
        let alertType = AlertType.whatsNewAlert(title: translations.title,
                                                text: translations.message,
                                                dismissButtonText: "Ok") {
            self.repository.markWhatsNewAsSeen(changeLog.lastId)
        }

        showAlertBlock(alertType)
    }

    internal func showMessage(_ message:Message) {
        let alertType = AlertType.message(text: message.message, dismissButtonText: "Ok") {
            self.repository.markMessageAsRead(message.id)
        }

        showAlertBlock(alertType)
    }

    internal func showRateReminder(_ rateReminder:RateReminder) {
        let alertType = AlertType(rateReminder: rateReminder) { result in
            self.repository.markRateReminderAsSeen(result)

            if result == .Rate, let link = rateReminder.link {
                _ = UIApplication.safeSharedApplication()?.safeOpenURL(link)
            }
        }

        showAlertBlock(alertType)
    }
}
