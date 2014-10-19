//
//  ViewController.swift
//  LBCacheImageDemo
//
//  Created by Lucian Boboc on 19/10/14.
//  Copyright (c) 2014 Lucian Boboc. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private var arr:[NSString]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.arr = ["http://www.lucianboboc.com/TEST/0.png"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arr.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cellIdentifier") as UITableViewCell
        
        var imageURL = self.arr[indexPath.row]
        cell.imageView.setImage(urlString: imageURL, placeholderImage: nil, options: .Default, progressBlock: { (progress) -> Void in
            println(progress)
            }) { (image, error) -> Void in
                println("image \(image)")
                println("error \(error)")
        }
        
        
        cell.textLabel.text = "\(indexPath.row)"
        return cell
    }


}

