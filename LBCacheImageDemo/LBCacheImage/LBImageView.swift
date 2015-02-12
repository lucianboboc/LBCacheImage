//
//  LBImageView.swift
//  SwiftProject
//
//  Created by Lucian Boboc on 18/10/14.
//  Copyright (c) 2014 Lucian Boboc. All rights reserved.
//

import UIkit
import ObjectiveC



//MARK: UIImageView extension
extension UIImageView {
    
    struct Associated {
        static let character:Character = "x"
    }
    
    //MARK: methods
    func setImage(#urlString:NSString, placeholderImage: UIImage?) {
        self.setImage(urlString: urlString, placeholderImage: placeholderImage, options: .Default, progressBlock: nil, completionBlock: nil)
    }
    
    func setImage(#urlString:NSString, placeholderImage: UIImage?, options: LBCacheImageOptions) {
        self.setImage(urlString: urlString, placeholderImage: placeholderImage, options: options, progressBlock: nil, completionBlock: nil)
    }
    
    func setImage(#urlString:NSString, placeholderImage: UIImage?, options: LBCacheImageOptions, completionBlock:LBCacheImageBlock?) {
        self.setImage(urlString: urlString, placeholderImage: placeholderImage, options: options, progressBlock: nil, completionBlock: completionBlock)
    }
    
    func setImage(#urlString:NSString, placeholderImage: UIImage?, options: LBCacheImageOptions, progressBlock:LBCacheProgressBlock? , completionBlock:LBCacheImageBlock?) {
        
        if placeholderImage != nil {
            self.image = placeholderImage!
        }
        
        self.cancelDownload()
        var imageOperation:ImageOperation? = LBCacheImage.sharedInstance().downloadImage(urlString: urlString, options: options, progressBlock: { (percent) -> Void in
            if progressBlock != nil {
                dispatch_async(dispatch_get_main_queue()) {
                    progressBlock!(percent)
                }
            }
            }) { [weak self] (image, error) -> Void in
                if error != nil {
                    println(error!.localizedDescription)
                }else {
                    dispatch_async(dispatch_get_main_queue()) {
                        self?.image = image
                        self?.setNeedsLayout()
                        
                        if completionBlock != nil {
                            completionBlock!(image, nil)
                        }
                    }
                }
        }
        
        var instance = Associated.character
        objc_setAssociatedObject(self, &instance, imageOperation, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }
    
    func imageFor(#urlString:NSString) -> UIImage? {
        var image = LBCacheImage.sharedInstance().imageFor(key: urlString)
        return image
    }
    
    func cancelDownload() {
        var instance = Associated.character
        var imageOperation = objc_getAssociatedObject(self, &instance) as? ImageOperation
        if imageOperation != nil {
            imageOperation!.cancel()
            objc_setAssociatedObject(self, &instance, nil, UInt(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
        }
    }
}
