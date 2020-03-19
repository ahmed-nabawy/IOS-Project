//
//  MoviesViewController.swift
//  Final
//
//  Created by iOS Training on 3/13/20.
//  Copyright © 2020 JETS. All rights reserved.
//

import UIKit
import Alamofire
import ReachabilitySwift

private let reuseIdentifier = "movieCell"

class MoviesViewController: UICollectionViewController {
    
    
    @IBOutlet weak var menu: UIBarButtonItem!
    var baseURL = "https://image.tmdb.org/t/p/w185/"
    var imagesNames: Array<String>!
    static var url: URLStringConvertible!
    static var which = true
    var det: DetailsTableViewController!
    var arr: Array<Dictionary<String, AnyObject>>!
    var offline: [Movie] = []
    var reachabilty = true

    static func setWhich(){
        if which {
            url = "https://api.themoviedb.org/3/discover/movie?api_key=42a37e68d24d50896269291a8cca1a93&language=en-US&sort_by=popularity.desc&include_adult=false&include_video=true&page=1&release_date.gte=2005" as URLStringConvertible
        }
        else {
            url = "https://api.themoviedb.org/3/discover/movie?api_key=42a37e68d24d50896269291a8cca1a93&language=en-US&sort_by=vote_average.desc&include_adult=false&include_video=true&page=1&release_date.gte=2005" as URLStringConvertible
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        det = self.storyboard?.instantiateViewControllerWithIdentifier("det") as! DetailsTableViewController
        
        imagesNames = []
        
        if revealViewController() != nil{
            menu.target = revealViewController()
            menu.action = #selector(SWRevealViewController.revealToggle(_:))
            view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
        }
        
        let reach = try! Reachability.reachabilityForInternetConnection()
        
        if reach.isReachable(){
            reachabilty = true
            whenReachable()
        }
        else {
            reachabilty = false
            offline = SQLite.instance.getAll()
            self.collectionView?.reloadData()
            print("not reachable")
        }
    }
    
    func whenReachable() {
        
        MoviesViewController.setWhich()
        
        request(.GET, MoviesViewController.url, parameters: nil, encoding: .URL, headers: nil).responseJSON { (response) in
            do{
                self.arr = try NSJSONSerialization.JSONObjectWithData(response.data!, options: NSJSONReadingOptions.AllowFragments).valueForKey("results") as! Array<Dictionary<String, AnyObject>>
                for i in 0...self.arr.count - 1 {
                    if i < self.arr.count {
                        if self.arr[i]["poster_path"]!.isEqual(NSNull()) {
                            print("null")
                            self.arr.removeAtIndex(i)
                        }
                        else{
                            self.imagesNames.append(self.arr[i]["poster_path"]! as! String)
                        }
                    }
                }
                self.collectionView?.reloadData()
            }catch{
            }
            
            for i in 0...(self.arr.count - 1) {
                let url = NSMutableURLRequest(URL: NSURL(string: self.baseURL + self.imagesNames[i])!)
                var filePath: NSURL!
                var fileName: String!
                download(url, destination: { (temp, response) in
                    if let directoryURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)[0] as? NSURL {
                        fileName = response.suggestedFilename!
                        filePath = directoryURL.URLByAppendingPathComponent(fileName)
                        return filePath
                    }
                    return temp
                }).response { (request, response, data, error) in
                    let movie = Movie(title: self.arr[i]["title"] as! String, image: fileName, relYear: self.arr[i]["release_date"] as! String, rate: self.arr[i]["vote_average"] as! Double, desc: self.arr[i]["overview"] as! String, id: self.arr[i]["id"] as! Int)
                    SQLite.instance.insert(movie)
                }
            }
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if reachabilty {
            return imagesNames.count
        }
        else {
            return offline.count
        }
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
        let imageView = cell.viewWithTag(1) as! UIImageView
        if reachabilty == true {
            imageView.sd_setImageWithURL(NSURL(string:baseURL + imagesNames[indexPath.row]))
        }
        else {
            var dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
            let docsDir = dirPaths[0] + "/" + offline[indexPath.row].image
            if NSFileManager.defaultManager().fileExistsAtPath(docsDir){
                let image = UIImage(data: NSData(contentsOfFile: docsDir)!)
                imageView.image = image
            }
        }
        return cell
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if reachabilty {
            var i = arr[indexPath.row]
            let m = Movie(title: i["title"] as! String, image: i["poster_path"] as! String, relYear: i["release_date"] as! String, rate: i["vote_average"] as! Double, desc: i["overview"] as! String, id: i["id"] as! Int)
            det.movie = m
        }
        else {
            det.movie = offline[indexPath.row]
        }
        self.navigationController?.pushViewController(det, animated: true)
    }
}
