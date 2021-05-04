//
//  ReposVM.swift
//  GithubSearch
//
//  Created by Shujat Ali on 5/4/21.
//

import UIKit
import Alamofire


extension ReposVC {
    // If a search was performed and then cleared,
    // refetch repos using user preferences.
    func refreshReposAfterSearch() {
        if isTextNotEmpty(searchBar.text) != nil || isTextNotEmpty(textFieldLanguage.text) != nil ||
            isTextNotEmpty(textFieldTopic.text) != nil {
            clearSearches()
            refreshRepos()
        }
    }

    func clearSearches() {
//        textFieldTopic.text = ""
//        textFieldLanguage.text = ""
//        searchBar.text = ""
        
    }

    // MARK: - User filter preferences

    func loadPreferencesIntoQueryMap() {
        rawQueryParams.removeAll()

        //let preferences = UserDefaults.standard
        //TODO: to load data from history
    }

    // MARK: - Search Repos
    @objc func refreshRepos() {
        // Clear repos
        repoList.removeAll()
        displayRepoList = repoList

        // Reset current page
        currentPage = 1
        allReposFetched = false

        // Fetch repos
        getRepos()
    }

    // Resets the display repo list to show all
    // the fetched repos in the table view.
    func resetDisplayedRepos() {
        displayRepoList = repoList
        querySearch.removeAll()
        topicSearch = ""
        languageSearch = ""
        errorNoRecords.isHidden = !displayRepoList.isEmpty
        tableView.reloadData()
    }
    
    func getRepos() {
        // Don't fetch repos if currently fetching or
        // if all repos have already been fetched.
        guard !isFetchingRepos && !allReposFetched else {
            return
        }

        loadPreferencesIntoQueryMap()
        
        
        
        searchRepos()
    }

    
    private func searchRepos() {
        activityIndicator.startAnimating()
        if let url = ApiWrapper.createSearchReposUrl(querySearch: querySearch, topicSearch: topicSearch, languageSearch: languageSearch, page: currentPage) {
            ApiWrapper.logRequest(url: url)

            isFetchingRepos = true
            hasLoadMoreData = false
            AF.request(url).responseJSON { [weak self ]response in
                guard let self = self else { return }
                self.activityIndicator.stopAnimating()
                switch response.result {
                case .success:
                    // response.result.value is a [String: Any] object
                    if let data = response.data{
                        do {
                            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                                if let itemsResponse = json["items"] as? [[String: Any]] {
                                    if(itemsResponse.isEmpty) {
                                        self.allReposFetched = true
                                    }

                                    for item in itemsResponse {
                                        let repo = GitItem(responseMap: item)
                                        self.repoList.append(repo)
                                    }
                                }
                                
                                if let count = json["total_count"] as? Int {
                                    
                                    self.setupToolTip(String(format: "Page %d\n %d\\%d", self.currentPage, self.repoList.count, count))
                                    self.hasLoadMoreData = count > self.repoList.count
                                }
                            }
                        } catch {
                            print("Failed to load" + error.localizedDescription)
                        }
                    }
                    
                    self.errorNoRecords.isHidden = !self.repoList.isEmpty
                    self.isFetchingRepos = false
//                    self.loadingView?.hideNotification()

                    self.resetDisplayedRepos()

                    if self.refreshControl.isRefreshing {
                        self.refreshControl.endRefreshing()
                    }

                case .failure:
                    let alertController = UIAlertController(title: "Network error", message: "Could not fetch repositorie", preferredStyle: .alert)

                    alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))

                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
}
