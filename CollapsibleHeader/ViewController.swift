//
//  ViewController.swift
//  CollapsibleHeader
//
//  Created by Guillaume on 12/02/2020.
//  Copyright © 2020 gdavo. All rights reserved.
//

import UIKit

/// Helper for collapsible header on top of a scroll view or a table view
///
/// The header bottom and scroll / table view top must have a size 0 vertical spacing constraint, and helper set as scroll / table view delegate
class CollapsibleHeaderHelper: NSObject, UITableViewDelegate {
    
    weak var view: UIView!
    weak var headerHeightConstraint: NSLayoutConstraint!
    
    let minHeaderHeight: CGFloat
    let maxHeaderHeight: CGFloat
    
    var previousScrollOffset: CGFloat = 0
    var isHeaderGrowing = false
    
    init(view: UIView, headerHeightConstraint: NSLayoutConstraint, maxHeaderHeight: CGFloat, minHeaderHeight: CGFloat = 0) {
        self.view = view
        self.headerHeightConstraint = headerHeightConstraint
        self.maxHeaderHeight = maxHeaderHeight
        self.minHeaderHeight = minHeaderHeight
    }
    
    // MARK: - update headerHeightConstraint depending on scroll
    
    private func canAnimateHeader(_ scrollView: UIScrollView) -> Bool {
        // Calculate the size of the scrollView when header is collapsed
        let scrollViewMaxHeight = scrollView.frame.height + self.headerHeightConstraint.constant - minHeaderHeight
        
        // Make sure that when header is collapsed, there is still room to scroll
        return scrollView.contentSize.height > scrollViewMaxHeight
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard canAnimateHeader(scrollView) else { return }
        
        // check if we are scrolling up or down and inside the content area
        let scrollDiff = scrollView.contentOffset.y - self.previousScrollOffset
        let absoluteTop: CGFloat = 0;
        let absoluteBottom: CGFloat = scrollView.contentSize.height - scrollView.frame.size.height;
        
        var newHeight = self.headerHeightConstraint.constant
        if scrollDiff > 0 && scrollView.contentOffset.y > absoluteTop {
            newHeight = max(self.minHeaderHeight, self.headerHeightConstraint.constant - abs(scrollDiff))
        } else if scrollDiff < 0 && scrollView.contentOffset.y < absoluteBottom {
            newHeight = min(self.maxHeaderHeight, self.headerHeightConstraint.constant + abs(scrollDiff))
        }
        
        if newHeight != self.headerHeightConstraint.constant {
            self.isHeaderGrowing = newHeight > self.headerHeightConstraint.constant
            self.headerHeightConstraint.constant = newHeight
            
            // translate scrollView content instead of scrolling if header is resizing
            scrollView.contentOffset = CGPoint(x: scrollView.contentOffset.x, y: self.previousScrollOffset)
        }
        
        self.previousScrollOffset = scrollView.contentOffset.y
    }
    
    // MARK: - snap header to max size
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.scrollDidStop()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            self.scrollDidStop()
        }
    }
    
    private func scrollDidStop() {
        if self.isHeaderGrowing {
            // expand header
            self.view.layoutIfNeeded()
            UIView.animate(withDuration: 0.2, animations: {
                self.headerHeightConstraint.constant = self.maxHeaderHeight
                self.view.layoutIfNeeded()
            })
        }
    }
}

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var headerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var tableView: UITableView!
    
    private lazy var helper = CollapsibleHeaderHelper(view: view, headerHeightConstraint: headerHeightConstraint, maxHeaderHeight: 100)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self.helper
    }
    
    
    // MARK: - UITableView Data Source
    
    let mockData = (0...20).map { (index) in
        return "Item \(index + 1)"
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mockData.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "myCell", for: indexPath)
        cell.textLabel?.text = mockData[indexPath.row]
        return cell
    }
    
}

