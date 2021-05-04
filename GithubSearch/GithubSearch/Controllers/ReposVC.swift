//
//  ReposVC.swift
//  GithubSearch
//
//  Created by Shujat Ali on 4/26/21.
//

import UIKit

class ReposVC: BaseVC, UISearchBarDelegate, UITextFieldDelegate {
    let searchBarPlaceholder = "Enter keywords"
    let navigationTitle = "Repos"
    
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

    // Infinite Scroll
    var currentPage = 1
    var isFetchingRepos = false
    var allReposFetched = false

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
        setupToolTip("Search by keyword \nor apply additional search by pressing filter button")
        setupSearchBar()
        setupNavigationBar()
        setupTextFields(false)
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

    func setupToolTip(_ msg: String) {
        errorLbl.text = msg
    }
    
    
    private func setupSearchBar() {
        searchBar.delegate = self
        searchBar.autocapitalizationType = .none
        if #available(iOS 13.0, *) {
            searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: searchBarPlaceholder, attributes: [NSAttributedString.Key.foregroundColor : UIColor.white])
        }
        // Make search cursor visible (not white)
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.black
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
}

