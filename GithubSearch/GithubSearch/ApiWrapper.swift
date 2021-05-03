//
//  ApiWrapper.swift
//  GithubSearch
//
//  Created by Shujat Ali on 4/26/21.
//

import Foundation

class ApiWrapper {
    
    static let secureScheme = "https"
    static let githubHost = "api.github.com"
    static let searchReposPath = "/search/repositories"
    
    static let searchQueryParamKey = "q"
    static let querySeparator = " "

    static let sortQueryParamKey = "sort"
    static let sortSeparator = "="

    static let pageQueryParamKey = "page"
    
    // Search API query param keys
    static let stars = "stars"
    static let language = "language"

    static let queryParamKey = "key"
    static let queryParamValue = "value"
    
    // MARK: - Build Request
    
    /**
        Sample search request:
        `https://api.github.com/search/repositories?q=ios user:kgleong language:swift stars:<=50`
    */
    class func createSearchReposUrl(querySearch: [String], topicSearch: String, languageSearch: String, page: Int) -> URL? {
        var queryItems = [URLQueryItem]()
        var queryString = ""
        
        if !querySearch.isEmpty {
            queryString = querySearch.joined(separator: querySeparator)
        }
        
        if !topicSearch.isEmpty {
            queryString += querySeparator + "topic:" + topicSearch
        }
        
        if !languageSearch.isEmpty {
            queryString += querySeparator + "language:" + languageSearch
        }
        
        queryItems.append(URLQueryItem(name: searchQueryParamKey, value: queryString))
        queryItems.append(URLQueryItem(name: pageQueryParamKey, value: String(page)))
        
        return createUrl(path: searchReposPath, queryParams: queryItems)
    }
    
    class func createUrl(path: String, queryParams: [URLQueryItem]?) -> URL? {
        let urlComponents = NSURLComponents()
        
        urlComponents.scheme = secureScheme
        urlComponents.host = githubHost
        urlComponents.path = path
        urlComponents.queryItems = [URLQueryItem]()
        
        if let queryParams = queryParams {
            urlComponents.queryItems!.append(contentsOf: queryParams)
        }
        
        return urlComponents.url
    }
    
    // MARK: - Logging
    
    class func logRequest(url: URL) {
        print("Making request to: \(url)")
    }
}
