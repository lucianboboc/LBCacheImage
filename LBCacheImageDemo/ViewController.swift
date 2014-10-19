//
//  ViewController.swift
//  LBCacheImageDemo
//
//  Created by Lucian Boboc on 19/10/14.
//  Copyright (c) 2014 Lucian Boboc. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private var arr:[NSString]!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.arr = ["http://www.lucianboboc.com/wong.png",
        "http://www.lucianboboc.com/TEST/0.png",
        "http://www.lucianboboc.com/TEST/1.png",
        "http://www.lucianboboc.com/TEST/2.png",
        "http://www.lucianboboc.com/TEST/3.png",
        "http://www.lucianboboc.com/TEST/4.png",
        "http://www.lucianboboc.com/TEST/0.png",
        "http://www.lucianboboc.com/TEST/1.png",
        "http://www.lucianboboc.com/TEST/2.png",
        "http://www.lucianboboc.com/TEST/3.png",
        "http://www.lucianboboc.com/TEST/4.png"]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arr.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("cellIdentifier") as MyCell
        
        var imageURL = self.arr[indexPath.row]
        
        cell.imgView.setImage(urlString: imageURL, placeholderImage: nil, options: .Default, progressBlock: { (progress) -> Void in
            println(progress)
            }) { [weak cell] (image, error) -> Void in
                dispatch_async(dispatch_get_main_queue()){
                    if error != nil {
                        println(error!)
                    }
                }
        }
        
        return cell
    }
    
    
    func tableView(tableView: UITableView, didEndDisplayingCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        var myCell = cell as MyCell
        myCell.imgView.cancelDownload()
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 100
    }

}

