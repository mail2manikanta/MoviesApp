//
//  MasterViewController.swift
//  MoviesApp
//
//  Created by Manikanta Nallabelly on 6/9/17.
//  Copyright © 2017 Platinum. All rights reserved.
//

import UIKit
import AFNetworking

class MasterViewController: UITableViewController {
    static let baseURL = "https://api.themoviedb.org/3/search/movie"
    static let apiKey = "40bb1f9f0fe7bd27bad69f05d58ac0a4"
    static let pageSize = 20

    let searchController = UISearchController(searchResultsController: nil)
    var detailViewController: DetailViewController? = nil
    var filteredObjects = [Movie]()
    var currentPage:Int {
        return filteredObjects.count/MasterViewController.pageSize
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl?.addTarget(self, action: #selector(loadMore), for: .valueChanged)
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        definesPresentationContext = true
        tableView.tableHeaderView = searchController.searchBar
        
        // Do any additional setup after loading the view, typically from a nib.
        navigationItem.leftBarButtonItem = editButtonItem

        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as! UINavigationController).topViewController as? DetailViewController
        }
    }

    func loadMore() {
        
        if searchController.isActive && searchController.searchBar.text != "" {
            filterContentForSearchText(searchController.searchBar.text!)
            tableView.reloadData()
            refreshControl?.endRefreshing()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let object = filteredObjects[indexPath.row]
                let controller = (segue.destination as! UINavigationController).topViewController as! DetailViewController
                controller.detailItem = object
                controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                controller.navigationItem.leftItemsSupplementBackButton = true
            }
        }
    }

    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.isActive && searchController.searchBar.text != "" {
            return filteredObjects.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let object:Movie
        if searchController.isActive && searchController.searchBar.text != "" {
            object = filteredObjects[indexPath.row]
            cell.textLabel!.text = object.movieTitle
        }
        return cell
    }

    
    func filterContentForSearchText(_ searchText:String) {
        
        let nextPage = self.currentPage + 1

        let parameters:[String:Any] = ["api_key":MasterViewController.apiKey, "query":searchText, "page":nextPage]
        AFHTTPSessionManager().get(
            MasterViewController.baseURL,
            parameters: parameters,
            success:
            {
                (operation, responseObject) in
                
                if let dic = responseObject as? [String: Any], let results = dic["results"] as? [[String: Any]] {
                    for movie in results {
                        let m = Movie(movieId: movie["id"] as! Int, movieTitle: movie["title"] as! String)
                        self.filteredObjects.insert(m, at: 0)
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
        },
            failure:
            {
                (operation, error) in
                print("Error: " + error.localizedDescription)
        })
    }
}

extension MasterViewController: UISearchResultsUpdating {
    
    public func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
}

extension MasterViewController:UISearchControllerDelegate {
    func didDismissSearchController(_ searchController: UISearchController) {
        self.filteredObjects.removeAll()
        tableView.reloadData()
    }
}

