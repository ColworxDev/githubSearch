//
//  ReposTblDelegate.swift
//  GithubSearch
//
//  Created by Shujat Ali on 5/4/21.
//

import UIKit
import SafariServices

extension ReposVC: UITableViewDelegate, UITableViewDataSource {
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
}
