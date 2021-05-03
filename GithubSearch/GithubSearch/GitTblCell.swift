//
//  GitTblCell.swift
//  GithubSearch
//
//  Created by Shujat Ali on 4/26/21.
//

import UIKit

class GitTblCell: UITableViewCell {
    @IBOutlet weak var repoNameLabel: UILabel!
    @IBOutlet weak var starCountLabel: UILabel!
    @IBOutlet weak var languageLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var shadowView: UIView!
    @IBOutlet weak var bodyView: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()

        setupViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

    // MARK: - Setup Views

    private func setupViews() {
        setupShadowView()
        setupBodyView()
        setupRepoInfoViews()
    }

    private func setupShadowView() {
        shadowView.backgroundColor = UIColor.clear
        shadowView.layer.shadowOpacity = 0.6
        shadowView.layer.shadowColor = UIColor.black.cgColor
        shadowView.layer.shadowRadius = 2.5 // blur
        shadowView.layer.shadowOffset = CGSize(width: 3, height: 3) // Spread
    }

    private func setupBodyView() {
        bodyView.layer.cornerRadius = 15.0
        bodyView.clipsToBounds = true
    }


    private func setupRepoInfoViews() {
        descriptionLabel.textColor = UIColor(red: 0.3, green: 0.3, blue: 0.5, alpha: 1)

    }
}
