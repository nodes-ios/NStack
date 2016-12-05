//
//  Repository.swift
//  NStackSDK
//
//  Created by Dominik Hádl on 02/12/2016.
//  Copyright © 2016 Nodes ApS. All rights reserved.
//

import Foundation
import Alamofire

typealias Completion<T> = ((DataResponse<T>) -> Void)

// MARK: - App Open -

protocol AppOpenRepository {
    func postAppOpen(oldVersion: String, currentVersion: String, acceptLanguage: String?,
                     completion: @escaping Completion<Any>)
}

// MARK: - Updates -

protocol UpdatesRepository {
    func fetchUpdates(oldVersion: String, currentVersion: String,
                      completion: @escaping Completion<Update>)
}

// MARK: - Translations -

protocol TranslationsRepository {
    func fetchTranslations(acceptLanguage: String, completion: @escaping Completion<TranslationsResponse>)
    func fetchCurrentLanguage(acceptLanguage: String, completion: @escaping Completion<Language>)
    func fetchAvailableLanguages(completion:  @escaping Completion<[Language]>)
}

// MARK: - Geography -

protocol GeographyRepository {
    func fetchCountries(completion:  @escaping Completion<[Country]>)
}

// MARK: - Versions -

protocol VersionsRepository {
    func markNewerVersionAsSeen(_ id: Int, appStoreButtonPressed: Bool)
    func markWhatsNewAsSeen(_ id: Int)
    func markMessageAsRead(_ id: String)
    func markRateReminderAsSeen(_ answer: AlertManager.RateReminderResult)
}
