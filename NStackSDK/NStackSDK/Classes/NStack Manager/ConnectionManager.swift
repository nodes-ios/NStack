//
//  ConnectionManager.swift
//  NStack
//
//  Created by Kasper Welner on 29/09/15.
//  Copyright © 2015 Nodes. All rights reserved.
//

import Foundation
import Alamofire
import Serpent

struct DataModel<T: Codable>: WrapperModelType {
    let model: T
    
    enum CodingKeys: String, CodingKey {
        case model = "data"
    }
}

protocol WrapperModelType: Codable {
    associatedtype ModelType: Codable
    var model: ModelType { get }
}

extension DataRequest {
    func responseCodable<T: Codable>(completion: @escaping (DataResponse<T>) -> Void) {
        validate().responseData { response in
            let dataResponse: DataResponse<T>
            
            switch response.result {
            case .success(let data):
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                do {
                    let decodedData = try decoder.decode(T.self, from: data)
                    dataResponse = DataResponse(request: self.request,
                                                response: self.response,
                                                data: data,
                                                result: .success(decodedData))
                } catch {
                    dataResponse = DataResponse(request: self.request,
                                                response: self.response,
                                                data: data,
                                                result: .failure(error))
                }
                
            case .failure(let error):
                dataResponse = DataResponse(request: self.request,
                                            response: self.response,
                                            data: nil,
                                            result: .failure(error))
            }
            
            completion(dataResponse)
        }
    }
    
    
    func responseCodable<M: WrapperModelType>(completion: @escaping (DataResponse<M.ModelType>) -> Void, wrapperType: M.Type) {
        validate().responseData { response in
            let dataResponse: DataResponse<M.ModelType>
            
            switch response.result {
            case .success(let data):
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                
                do {
                    let parentData = try decoder.decode(wrapperType, from: data)
                    dataResponse = DataResponse(request: self.request,
                                                response: self.response,
                                                data: data,
                                                result: .success(parentData.model))
                } catch {
                    dataResponse = DataResponse(request: self.request,
                                            response: self.response,
                                            data: data,
                                            result: .failure(error))
                }
                
            case .failure(let error):
                dataResponse = DataResponse(request: self.request,
                                        response: self.response,
                                        data: nil,
                                        result: .failure(error))
            }
            
            completion(dataResponse)
        }
    }
}

// FIXME: Figure out how to do accept language header properly
final class ConnectionManager {
    let baseURL = "https://nstack.io/api/v1/"
    let defaultUnwrapper: Parser.Unwrapper = { dict, _ in dict["data"] }
    let passthroughUnwrapper: Parser.Unwrapper = { dict, _ in return dict }

    let manager: SessionManager
    let configuration: APIConfiguration

    var defaultHeaders: [String : String] {
        return [
            "X-Application-id"  : configuration.appId,
            "X-Rest-Api-Key"    : configuration.restAPIKey,
        ]
    }

    init(configuration: APIConfiguration) {
        let sessionConfiguration = SessionManager.default.session.configuration
        sessionConfiguration.timeoutIntervalForRequest = 20.0

        self.manager = SessionManager(configuration: sessionConfiguration)
        self.configuration = configuration
    }
}

extension ConnectionManager: AppOpenRepository {
    func postAppOpen(oldVersion: String = VersionUtilities.previousAppVersion,
                     currentVersion: String = VersionUtilities.currentAppVersion,
                     acceptLanguage: String? = nil, completion: @escaping Completion<Any>) {
        var params: [String : Any] = [
            "version"           : currentVersion,
            "guid"              : Configuration.guid,
            "platform"          : "ios",
            "last_updated"      : ConnectionManager.lastUpdatedString,
            "old_version"       : oldVersion
        ]

        if let overriddenVersion = VersionUtilities.versionOverride {
            params["version"] = overriddenVersion
        }

        var headers = defaultHeaders
        if let acceptLanguage = acceptLanguage {
            headers["Accept-Language"] = acceptLanguage
        }

        let url = baseURL + "open" + (configuration.isFlat ? "?flat=true" : "")

        manager
            .request(url, method: .post, parameters: params, headers: headers)
            .responseJSON(completionHandler: completion)
    }
}

extension ConnectionManager: TranslationsRepository {
    func fetchTranslations(acceptLanguage: String,
                           completion: @escaping Completion<TranslationsResponse>) {
        let params: [String : Any] = [
            "guid"              : Configuration.guid,
            "last_updated"      : ConnectionManager.lastUpdatedString
        ]

        let url = configuration.translationsUrlOverride ?? baseURL + "translate/mobile/keys?all=true" + (configuration.isFlat ? "&flat=true" : "")

        var headers = defaultHeaders
        headers["Accept-Language"] = acceptLanguage

        manager
            .request(url, method: .get, parameters:params, headers: headers)
            .responseSerializable(completion, unwrapper: passthroughUnwrapper)
    }

    func fetchCurrentLanguage(acceptLanguage: String,
                              completion:  @escaping Completion<Language>) {
        let params: [String : Any] = [
            "guid"              : Configuration.guid,
            "last_updated"      : ConnectionManager.lastUpdatedString
        ]

        let url = baseURL + "translate/mobile/languages/best_fit?show_inactive_languages=true"

        var headers = defaultHeaders
        headers["Accept-Language"] = acceptLanguage

        manager
            .request(url, method: .get, parameters: params, headers: headers)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }

    func fetchAvailableLanguages(completion:  @escaping Completion<[Language]>) {
        let params: [String : Any] = [
            "guid"              : Configuration.guid,
        ]

        let url = baseURL + "translate/mobile/languages"

        manager
            .request(url, method: .get, parameters:params, headers: defaultHeaders)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }

    func fetchPreferredLanguages() -> [String] {
        return Locale.preferredLanguages
    }

    func fetchBundles() -> [Bundle] {
        return Bundle.allBundles
    }
}

extension ConnectionManager: UpdatesRepository {
    func fetchUpdates(oldVersion: String = VersionUtilities.previousAppVersion,
                      currentVersion: String = VersionUtilities.currentAppVersion,
                      completion: @escaping Completion<Update>) {
        let params: [String : Any] = [
            "current_version"   : currentVersion,
            "guid"              : Configuration.guid,
            "platform"          : "ios",
            "old_version"       : oldVersion,
            ]

        let url = baseURL + "notify/updates"
        manager
            .request(url, method: .get, parameters:params, headers: defaultHeaders)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }
}

extension ConnectionManager: VersionsRepository {
    func markWhatsNewAsSeen(_ id: Int) {
        let params: [String : Any] = [
            "guid"              : Configuration.guid,
            "update_id"         : id,
            "type"              : "new_in_version",
            "answer"            : "no",
        ]

        let url = baseURL + "notify/updates/views"
        manager.request(url, method: .post, parameters:params, headers: defaultHeaders)
    }

    func markMessageAsRead(_ id: String) {
        let params: [String : Any] = [
            "guid"              : Configuration.guid,
            "message_id"        : id
        ]

        let url = baseURL + "notify/messages/views"
        manager.request(url, method: .post, parameters:params, headers: defaultHeaders)
    }

    #if os(iOS) || os(tvOS)
    func markRateReminderAsSeen(_ answer: AlertManager.RateReminderResult) {
        let params: [String : Any] = [
            "guid"              : Configuration.guid,
            "platform"          : "ios",
            "answer"            : answer.rawValue
        ]

        let url = baseURL + "notify/rate_reminder/views"
        manager.request(url, method: .post, parameters:params, headers: defaultHeaders)
    }
    #endif
}

// MARK: - Geography -

extension ConnectionManager: GeographyRepository {
    func fetchContinents(completion: @escaping Completion<[Continent]>) {
        manager
            .request(baseURL + "geographic/continents", headers: defaultHeaders)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }
    
    func fetchLanguages(completion: @escaping Completion<[Language]>) {
        manager
            .request(baseURL + "geographic/languages", headers: defaultHeaders)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }
    
    func fetchTimeZones(completion: @escaping Completion<[Timezone]>) {
        manager
            .request(baseURL + "geographic/time_zones", headers: defaultHeaders)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }
    
    func fetchTimeZone(lat: Double, lng: Double, completion: @escaping Completion<Timezone>) {
        manager
            .request(baseURL + "geographic/time_zones/by_lat_lng?lat_lng=\(String(lat)),\(String(lng))", headers: defaultHeaders)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }
    
    func fetchIPDetails(completion: @escaping Completion<IPAddress>) {
        manager
            .request(baseURL + "geographic/ip-address", headers: defaultHeaders)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }
    
    func fetchCountries(completion:  @escaping Completion<[Country]>) {
        manager
            .request(baseURL + "geographic/countries", headers: defaultHeaders)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }
}

// MARK: - Validation -

extension ConnectionManager: ValidationRepository {
    func validateEmail(_ email: String, completion:  @escaping Completion<Validation>) {
        manager
            .request(baseURL + "validator/email?email=\(email)", headers: defaultHeaders)
            .responseCodable(completion: completion, wrapperType: DataModel.self)
    }
}

// MARK: - Content -

extension ConnectionManager: ContentRepository {
    
    struct DataWrapper<T: Codable>: Swift.Codable {
        var data: T
    }
    
    func fetchStaticResponse<T:Swift.Codable>(atSlug slug: String, completion: @escaping ((NStack.Result<T>) -> Void)) {
      
        manager
            .request(baseURL + "content/responses/\(slug)", headers: defaultHeaders)
            .validate()
            .responseData { (response) in
                switch response.result {
                case .success(let jsonData):
                    
                    do {
                       
                        let decoder = JSONDecoder()
                        let wrapper: DataWrapper<T> = try decoder.decode(DataWrapper<T>.self, from: jsonData)
                        completion(NStack.Result.success(data: wrapper.data))
                    } catch let err {
                         completion(.failure(err))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }
    
    func fetchContent(_ id: Int, completion: @escaping Completion<Any>) {
        manager
            .request(baseURL + "content/responses/\(id)", headers: defaultHeaders)
            .validate()
            .responseJSON(completionHandler: completion)
    }
    
    func fetchContent(_ slug: String, completion: @escaping Completion<Any>) {
        manager
            .request(baseURL + "content/responses/\(slug)", headers: defaultHeaders)
            .validate()
            .responseJSON(completionHandler: completion)
    }
}

// MARK: - Collections -
extension ConnectionManager: ColletionRepository {
    func fetchCollection<T: Swift.Codable>(_ id: Int, completion: @escaping ((NStack.Result<T>) -> Void)) {
        manager
            .request(baseURL + "content/collections/\(id)", headers: defaultHeaders)
            .validate()
            .responseData { (response) in
                switch response.result {
                case .success(let jsonData):
                    do {
                        
                        let decoder = JSONDecoder()
                        let wrapper: DataWrapper<T> = try decoder.decode(DataWrapper<T>.self, from: jsonData)
                        
                        completion(NStack.Result.success(data: wrapper.data))
                    } catch let err {
                        completion(.failure(err))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
        }
    }
}

// MARK: - Utility Functions -

// FIXME: Refactor

extension ConnectionManager {

    static var lastUpdatedString: String {
        let cache = Constants.persistentStore

        // FIXME: Handle language change
//        let previousAcceptLanguage = cache.string(forKey: Constants.CacheKeys.prevAcceptedLanguage)
//        let currentAcceptLanguage  = TranslationManager.acceptLanguage()
//
//        if let previous = previousAcceptLanguage, previous != currentAcceptLanguage {
//            cache.setObject(currentAcceptLanguage, forKey: Constants.CacheKeys.prevAcceptedLanguage)
//            setLastUpdated(Date.distantPast)
//        }

        let key = Constants.CacheKeys.lastUpdatedDate
        let date = cache.object(forKey: key) as? Date ?? Date.distantPast
        return date.stringRepresentation()
    }

    func setLastUpdated(toDate date: Date = Date()) {
        Constants.persistentStore.setObject(date, forKey: Constants.CacheKeys.lastUpdatedDate)
    }
}
