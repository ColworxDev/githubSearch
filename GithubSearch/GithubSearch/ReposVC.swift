//
//  ReposVC.swift
//  GithubSearch
//
//  Created by Shujat Ali on 4/26/21.
//

import UIKit
import Alamofire
import SafariServices

class ReposVC: BaseVC, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate {
    let searchBarPlaceholder = "Enter keywords"
    let navigationTitle = "Repos"
    let settingsSegueId = "com.orangemako.GithubClient.settingsSegue"

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var errorNoRecords: UILabel!
    
    // Tool Tip
    @IBOutlet weak var toolTipView: UIView!
    @IBOutlet weak var toolTipLabel: UILabel!
    @IBOutlet weak var toolTipBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var toolTipTopConstraint: NSLayoutConstraint!
    
    // Text Fields
    @IBOutlet weak var textFieldTopic: UITextField!
    @IBOutlet weak var textFieldLanguage: UITextField!
    
    // Error Label
    @IBOutlet weak var errorLbl: UILabel!

    var rawQueryParams = [[String: String]]()
    var querySearch: [String] = []
    var topicSearch: String = ""
    var languageSearch: String = ""
    var hasLoadMoreData = false
    
    var searchBar = UISearchBar()
//    var settingsViewController: SettingsViewController?

    // Infinite Scroll
    var currentPage = 1
    var isFetchingRepos = false
    var allReposFetched = false

//    var loadingView: CustomNotificationView?

    // All fetched repos
    var repoList = [GitItem]()

    // Repos displayed in the table view.
    var displayRepoList = [GitItem]()

    var refreshControl = UIRefreshControl()

    // MARK: - ViewController overrides

    override func viewDidLoad() {
        super.viewDidLoad()

        setupViews()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

        
    // MARK: - Setup Views

    private func setupViews() {
        title = navigationTitle
        
        setupTableView()
        setupLoadingView()
        setupToolTip("Search by keyword \nor apply additional search by pressing filter button")
        setupSearchBar()
        setupNavigationBar()
        setupSettings()
        setupTextFields(false)
    }

    private func setupLoadingView() {
//        loadingView = CustomNotificationView(parentView: self.view)
//        loadingView?.title = "Loading"
//        loadingView?.showSpinner = true
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.clear

        // Make cell height dynamic
        tableView.estimatedRowHeight = 200.0
        tableView.rowHeight = UITableView.automaticDimension



        /*
            A UIRefreshControl sends a `valueChanged` event to signal
            when a refresh should occur.
        */
        refreshControl.addTarget(self, action: #selector(ReposVC.refreshRepos), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }

    private func setupToolTip(_ msg: String) {
        errorLbl.text = msg
    }
    
    
    

    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: searchBarPlaceholder, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])


        // Make search cursor visible (not white)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.black
    }
    
    private func setupSettings() {
//        settingsViewController =
//            UIStoryboard(
//                name: "Main",
//                bundle: nil
//            ).instantiateViewController(
//                withIdentifier: SettingsViewController.storyboardId
//            ) as? SettingsViewController
    }
    
    private func setupTextFields(_ isShow: Bool) {
        textFieldTopic.superview?.isHidden = !isShow
        textFieldLanguage.superview?.isHidden = !isShow
    }
    
    private func setupNavigationBar() {
        navigationController?.navigationBar.tintColor = UIColor.white
        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white]
        
        navigationItem.titleView = searchBar
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init(image: UIImage(named: "filter"), style: .plain, target: self, action: #selector(ReposVC.displaySettings))
    }
    
    // MARK: UI Target Actions
    
    @objc private func displaySettings() {
        setupTextFields((textFieldLanguage.superview?.isHidden ?? false))
    }
    
    // MARK: - UITableView Delegate Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayRepoList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GitTblCell") as! GitTblCell
        cell.backgroundColor = UIColor.clear

        // Avoids index out of bounds errors when the displayed list is empty
        guard !displayRepoList.isEmpty else {
            return cell
        }

        populateRepoCell(cell: cell, repo: displayRepoList[indexPath.row])

        // Infinite scroll
        if(hasLoadMoreData && indexPath.row == repoList.count - 1 && indexPath.row != 0) {
            currentPage += 1
            getRepos()
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Open a Safari controller if a URL exists for the repostitory.
        if let rawUrl = displayRepoList[indexPath.row].repoUrl, let url = URL(string: rawUrl) {
            let safariController = SFSafariViewController(url: url)
            present(safariController, animated: true, completion: nil)
        }
        else {
            let alert =  UIAlertController.init(title: nil, message: "Invalid Repository Url", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func populateRepoCell(cell: GitTblCell, repo: GitItem) {
        cell.repoNameLabel.text = repo.fullName
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal

        cell.selectionStyle = .none

        if let starCount = repo.starCount {
            cell.starCountLabel.text = numberFormatter.string(from: NSNumber(value: starCount))
        }

        if let language = repo.language {
            cell.languageLabel.text = language
        }
        else {
            // Collapses the label if there's no language
            cell.languageLabel.text = nil
        }

        if let repoDescription = repo.repoDescription {
            cell.descriptionLabel.text = repoDescription
        }
        else {
            cell.descriptionLabel.text = nil
        }
    }

    // MARK: - UITextfieldDelegate
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if string == "" { return true }
        do {
            let regex = try NSRegularExpression(pattern: "[a-zA-Z0-9-.+_]$", options: .caseInsensitive)
            if regex.numberOfMatches(in: string, options: [], range: NSRange(location: 0, length: string.count)) == 0 {
                return false
            }
        } catch {
            
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == textFieldTopic {
            textFieldLanguage.becomeFirstResponder()
        } else {
            searchBarSearchButtonClicked(searchBar)
        }
        return true
    }
    
    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        guard (searchText.count > 0) else {
            resetDisplayedRepos()
            return
        }

        do {
            displayRepoList = try repoList.filter() {
                (repo: GitItem) throws -> Bool
                in
                let regex = try NSRegularExpression(pattern: "\(searchText)", options: [NSRegularExpression.Options.caseInsensitive])

                var numNameMatches = 0
                var numOwnerNameMatches = 0
                var numDescriptionMatches = 0

                if let name = repo.name {
                    numNameMatches = regex.numberOfMatches(in: name, options: [], range: NSRange(location: 0, length: name.count))
                }

                if let ownerName = repo.ownerLoginName {
                    numOwnerNameMatches = regex.numberOfMatches(in: ownerName, options: [], range: NSRange(location: 0, length: ownerName.count))
                }

                if let repoDescription = repo.repoDescription {
                    numDescriptionMatches = regex.numberOfMatches(in: repoDescription, options: [], range: NSRange(location: 0, length: repoDescription.count))
                }

                if(numNameMatches + numOwnerNameMatches + numDescriptionMatches > 0) {
                    return true
                }
                else {
                    return false
                }
            }
        }
        catch {
            // NSRegularExpression error
            print("\(error)")
        }
        errorNoRecords.isHidden = !displayRepoList.isEmpty
        tableView.reloadData()
    }

    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        tableView.setContentOffset(CGPoint.zero, animated: true)
        searchBar.showsCancelButton = true

    }

    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = nil
        searchBar.showsCancelButton = false

        if textFieldTopic.text?.isEmpty ?? false || textFieldLanguage.text?.isEmpty ?? false {
            resetDisplayedRepos()
        }
        else {
            refreshReposAfterSearch()
        }

        searchBar.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        if let searchtxt = isTextNotEmpty(searchBar.text) {
            querySearch = searchtxt
        }
        if let searchtxt = isTextNotEmpty(textFieldLanguage.text) {
            languageSearch = searchtxt.first ?? ""
        }
        
        if let searchtxt = isTextNotEmpty(textFieldTopic.text) {
            topicSearch = searchtxt.first ?? ""
        }
        clearSearches()
        refreshRepos()
        
        searchBar.endEditing(true)
    }

    // If a search was performed and then cleared,
    // refetch repos using user preferences.
    func refreshReposAfterSearch() {
        if isTextNotEmpty(searchBar.text) != nil || isTextNotEmpty(textFieldLanguage.text) != nil ||
            isTextNotEmpty(textFieldTopic.text) != nil {
            clearSearches()
            refreshRepos()
        }
    }

    private func clearSearches() {
//        textFieldTopic.text = ""
//        textFieldLanguage.text = ""
//        searchBar.text = ""
        
    }

    // MARK: - User filter preferences

    private func loadPreferencesIntoQueryMap() {
        rawQueryParams.removeAll()

        let preferences = UserDefaults.standard

//        if let minStars = preferences.value(forKey: SettingsViewController.minStarsKey) as? Int {
//            rawQueryParams.append(createQueryParamMapEntry(key: GithubClient.stars, value: String(minStars)))
//        }

//        if let searchByLanguageEnabled = preferences.value(forKey: SettingsViewController.searchByLanguageEnabledKey) as? Bool {
//            if(searchByLanguageEnabled) {
//                // Only add language filters if the language filter toggle is enabled.
//                if let languages = preferences.value(forKey: SettingsViewController.selectedLanguagesKey) as? [String] {
//                    for language in languages {
//                        rawQueryParams.append(
//                            createQueryParamMapEntry(key: GithubClient.language, value: language)
//                        )
//                    }
//                }
//            }
//        }

    }

    private func createQueryParamMapEntry(key: String, value: String) -> [String: String] {
        return
            [
                "\(ApiWrapper.queryParamKey)": "\(key)",
                "\(ApiWrapper.queryParamValue)": "\(value)",
            ]
    }

    // MARK: - Search Repos

    @objc private func refreshRepos() {
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
    private func resetDisplayedRepos() {
        displayRepoList = repoList
        querySearch.removeAll()
        topicSearch = ""
        languageSearch = ""
        errorNoRecords.isHidden = !displayRepoList.isEmpty
        tableView.reloadData()
    }
    
    private func getRepos() {
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
//            loadingView?.displayNotification(shouldFade: false, onComplete: nil)
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

