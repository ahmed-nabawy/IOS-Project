//
//  FavoritesViewController.swift
//  Final
//
//  Created by iOS Training on 3/13/20.
//  Copyright © 2020 JETS. All rights reserved.
//

import UIKit

private let reuseIdentifier = "favoriteCell"

class FavoritesViewController: UICollectionViewController {
    
    var movies: [Movie]!
    var det: DetailsTableViewController!

    override func viewWillAppear(animated: Bool) {
        movies = SQLite.instance.getFavorites()
        det = self.storyboard?.instantiateViewControllerWithIdentifier("det") as! DetailsTableViewController
        self.collectionView?.reloadData()
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return movies.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath)
        let imageView = cell.viewWithTag(1) as! UIImageView
        var dirPaths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)
        let docsDir = dirPaths[0] + "/" + movies[indexPath.row].image
        if NSFileManager.defaultManager().fileExistsAtPath(docsDir){
            let image = UIImage(data: NSData(contentsOfFile: docsDir)!)
            imageView.image = image
        }
        
        
        // Configure the cell
    
        return cell
    }

    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print(indexPath.row)
        det.movie = movies[indexPath.row]
        self.navigationController?.pushViewController(det, animated: true)
    }
}
