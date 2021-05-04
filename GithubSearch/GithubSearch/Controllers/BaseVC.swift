//
//  BaseVC.swift
//  GithubSearch
//
//  Created by Shujat Ali on 4/27/21.
//

import UIKit

class BaseVC: UIViewController {
    
    func isTextNotEmpty(_ text: String?) -> [String]? {
        if let searchtxt = text, !searchtxt.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).isEmpty {
            return searchtxt.components(separatedBy: " ")
        }
        return nil
    }
}
