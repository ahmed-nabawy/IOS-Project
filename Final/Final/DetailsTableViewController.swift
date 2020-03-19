//
//  DetailsTableViewController.swift
//  Final
//
//  Created by iOS Training on 3/17/20.
//  Copyright © 2020 JETS. All rights reserved.
//

import Cosmos
import Alamofire

class DetailsTableViewController: UITableViewController {

    var movie: Movie!
    var arr: Array<Dictionary<String, AnyObject>>!
    let baseURL = "https://image.tmdb.org/t/p/w185/"
    let youtube = "https://www.youtube.com/watch?v="
    let start = "https://api.themoviedb.org/3/movie/"
    let end = "/videos?api_key=42a37e68d24d50896269291a8cca1a93&language=en-US"
    var keys: [String]!
    
    @IBOutlet weak var movieTitle: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var rel: UILabel!
    @IBOutlet weak var stars: CosmosView!
    @IBOutlet weak var desc: UILabel!
    @IBOutlet weak var web2: UIWebView!
    @IBOutlet weak var web1: UIWebView!
    
    @IBAction func addToFavorites(sender: AnyObject) {
        SQLite.instance.update(movie.id)
    }
    override func viewWillAppear(animated: Bool) {
        movieTitle.text = movie.title
        keys = []
        image.sd_setImageWithURL(NSURL(string: baseURL + movie.image))
        rel.text = movie.relYear
        stars.rating = movie.rating / 2
        desc.text = movie.desc
        request(.GET, (start + String(movie.id) + end) as URLStringConvertible).responseJSON { (response) in
            do{
                self.arr = try NSJSONSerialization.JSONObjectWithData(response.data!, options: NSJSONReadingOptions.AllowFragments).valueForKey("results") as! Array<Dictionary<String, AnyObject>>
                if self.arr.count != 0 {
                    if self.arr.count != 1 {
                        self.keys.append(self.arr[0]["key"] as! String)
                        self.keys.append(self.arr[1]["key"] as! String)
                        self.web1.loadRequest(NSURLRequest(URL: NSURL(string: self.youtube + self.keys[0])!))
                        self.web2.loadRequest(NSURLRequest(URL: NSURL(string: self.youtube + self.keys[1])!))
                    }
                    else{
                        self.keys.append(self.arr[0]["key"] as! String)
                        self.web1.loadRequest(NSURLRequest(URL: NSURL(string: self.youtube + self.keys[0])!))
                    }
                }
            }
            catch{
            }
        }
    }
}
