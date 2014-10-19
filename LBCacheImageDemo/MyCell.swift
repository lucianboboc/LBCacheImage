//
//  MyCell.swift
//  LBCacheImageDemo
//
//  Created by Lucian Boboc on 19/10/14.
//  Copyright (c) 2014 Lucian Boboc. All rights reserved.
//

import UIKit

class MyCell: UITableViewCell {
    @IBOutlet var imgView:UIImageView!
    
    override func prepareForReuse() {
        self.imgView.image = nil
    }
}
