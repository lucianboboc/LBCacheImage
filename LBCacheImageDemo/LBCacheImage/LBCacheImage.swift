//
//  LBCacheImage.swift
//  SwiftProject
//
//  Created by Lucian Boboc on 18/10/14.
//  Copyright (c) 2014 Lucian Boboc. All rights reserved.
//

import UIKit


typealias LBCacheImageBlock = (UIImage?, NSError?) -> Void
typealias LBCacheProgressBlock = (Double) -> Void

let kDaysToKeepCache = 3

// notifications are posted on the main thread
let LBCacheImageDownloadDidStartNotification = "LBCacheImageDownloadDidStartNotification"
let LBCacheImageDownloadDidStopNotification = "LBCacheImageDownloadDidStopNotification"

let kLBCacheErrorDomain = "LBCacheErrorDomain"

let kImageNotFoundDescription = "The image was not found at the local path in cache."
let kCantCreateImageDescription = "The image can't be created from NSData or local path."
let kNilDownloadURLLocation = "The download URL location is nil."
let kNilURLStringToHash = "Can't create the hash from the image URL string."
let kNilLBCacheDicrectory = "LBCacheDirectory is nil."


enum LBCacheImageError: Int {
    // the image was not found at local path in cache
    case ImageNotFound = 0
    
    // the image can't be created from the NSData object
    case CantCreateImage = 1
    
    // the download url location is nil
    case NilDownloadLocation = 2
    
    // the hash can't be created from the image url string
    case NilHashFromURLString = 3
    
    // the LBCacheDirectory is nil
    case NilCacheDirectory = 4
    
    // the URL can't be created from urlString
    case UrlStringNotValid = 5
}




enum LBCacheImageOptions {
    // default option will search first into the cache, if the image is not found will download from the web.
    case Default
    
    // web option will download the image using from the web, if there is no internet connection or it fails, it will load the image from the cache if it was saved before.
    case ReloadFromWebOrCache
    
    // cache option will search only into the cache
    case LoadOnlyFromCache
}




//MARK: LBCacheImage class
class LBCacheImage {
    
    //MARK: class properties and inittialization
    private var _memoryCache:NSCache?
    private var memoryCache:NSCache {
        get {
            if _memoryCache == nil {
                _memoryCache = NSCache()
            }
            return _memoryCache!
        }
    }
    
    private var _imagesQueue:NSOperationQueue?
    private var imagesQueue:NSOperationQueue {
        get {
            if _imagesQueue == nil {
                _imagesQueue = NSOperationQueue()
                _imagesQueue!.maxConcurrentOperationCount = 1
            }
            return _imagesQueue!
        }
    }
    
    class func sharedInstance() -> LBCacheImage {
        
        struct Singleton {
                static var instance:LBCacheImage?
                static var token: dispatch_once_t = 0
            }
            
            var token = Singleton.token
            dispatch_once(&token) {
                Singleton.instance = LBCacheImage()
                NSNotificationCenter.defaultCenter().addObserver(Singleton.instance!, selector: Selector("clearCache"), name: UIApplicationDidReceiveMemoryWarningNotification, object: UIApplication.sharedApplication())
                NSNotificationCenter.defaultCenter().addObserver(Singleton.instance!, selector: Selector("clearCache"), name: UIApplicationWillTerminateNotification, object: UIApplication.sharedApplication())
            }
        
        return Singleton.instance!
    }
    
    init() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("clearCache"), name: UIApplicationDidReceiveMemoryWarningNotification, object: UIApplication.sharedApplication())
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("clearCache"), name: UIApplicationWillTerminateNotification, object: UIApplication.sharedApplication())
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationDidReceiveMemoryWarningNotification, object: UIApplication.sharedApplication())
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIApplicationWillTerminateNotification, object: UIApplication.sharedApplication())
    }
    
    
    //MARK: public methods
    func getLBCacheDirectory() -> NSURL? {
        var fm = NSFileManager()
        var cachesURL = self.applicationCachesDirectory()
        if cachesURL != nil {
            var imagesURLDirectory = cachesURL!.URLByAppendingPathComponent("LBCacheDirectory")
            
            var isDir = ObjCBool(false)
            var error:NSError? = nil
            if fm.fileExistsAtPath(imagesURLDirectory.path!, isDirectory: &isDir) == false {
                var success = fm.createDirectoryAtURL(imagesURLDirectory, withIntermediateDirectories: true, attributes: nil, error: &error)
                if !success {
                    return nil
                }else {
                    return imagesURLDirectory
                }
            }else {
                return imagesURLDirectory
            }
        }
        return nil
    }
    
    func applicationCachesDirectory() -> NSURL? {
        var url: AnyObject? = NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: NSSearchPathDomainMask.UserDomainMask).last
        return url as? NSURL
    }
    
    func imageFor(#key:NSString) -> UIImage? {
        if let image: AnyObject = self.memoryCache.objectForKey(key) {
            return image as? UIImage
        }else {
            if let path = self.imagePathLocation(key: key) {
                var image = UIImage(contentsOfFile: path as String)
                return image
            }else {
                return nil
            }
        }
    }
    
    
    func imagePathLocation(#key:NSString) -> NSString? {
        if let directory = self.getLBCacheDirectory() {
            if let imageName = key.hashWithType(.MD5) {
                var imageURL = directory.URLByAppendingPathComponent(imageName as String)
                var fm = NSFileManager()
                if fm.fileExistsAtPath(imageURL.path!) {
                    return imageURL.path!
                }
            }
        }
        return nil
    }
    
    
    
    
    
    //MARK: cache and disk methods
    private func removeCachedImages() {
        dispatch_async(dispatch_get_global_queue(0, 0), { () -> Void in
            var lbCacheDirectory:NSURL? = self.getLBCacheDirectory()
            
            if lbCacheDirectory != nil {
                var fm = NSFileManager()
                var error:NSError? = nil
                var images:NSArray? = fm.contentsOfDirectoryAtURL(lbCacheDirectory!, includingPropertiesForKeys: [NSFileModificationDate], options: NSDirectoryEnumerationOptions.SkipsHiddenFiles, error: &error)
                if error != nil {
                    println("contentsOfDirectoryAtURL error:" + error!.localizedDescription)
                }
                
                if images != nil {
                    var components = NSDateComponents()
                    components.day = -(kDaysToKeepCache)
                    var expirationDate:NSDate? = NSCalendar.currentCalendar().dateByAddingComponents(components, toDate: NSDate(), options: nil)
                    if expirationDate != nil {
                        for(var i = 0; i < images!.count; i++) {
                            var url = images![i] as? NSURL
                            if url != nil {
                                var attributes:NSDictionary? = fm.attributesOfFileSystemForPath(url!.path!, error: nil)
                                if attributes != nil {
                                    var date = attributes!.objectForKey(NSFileModificationDate) as? NSDate
                                    if date != nil {
                                        if expirationDate!.compare(date!) == .OrderedDescending {
                                            fm.removeItemAtPath(url!.path!, error: nil)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        })
    }
    
    
    
    private func clearCache() {
        self.removeCachedImages()
        self.memoryCache.removeAllObjects()
    }
    
    
    //MARK: image download methods
    func downloadImage(#urlString:NSString, options: LBCacheImageOptions, progressBlock: LBCacheProgressBlock?, completionBlock: LBCacheImageBlock) -> ImageOperation? {
        
            var imageOperation:ImageOperation? = nil
            if options == .Default {
                if let image = self.memoryCache.objectForKey(urlString) as? UIImage {
                    completionBlock(image, nil)
                }else {
                    imageOperation = self.loadImageFromDiskOrFromWeb(urlString: urlString, progressBlock: progressBlock, completionBlock: completionBlock)
                }
            } else if options == .LoadOnlyFromCache {
                if let image = self.memoryCache.objectForKey(urlString) as? UIImage {
                    completionBlock(image, nil)
                }else {
                    self.loadImageFromDisk(urlString: urlString, completionBlock: completionBlock)
                }
            }else {
                imageOperation = self.downloadImageFromWebOrLoadFromCache(urlString: urlString, progressBlock: progressBlock, completionBlock: completionBlock)
        }
        
        
        return imageOperation
    }
    
    private func loadImageFromDiskOrFromWeb(#urlString:NSString, progressBlock: LBCacheProgressBlock?, completionBlock: LBCacheImageBlock) -> ImageOperation? {
        var imageOperation:ImageOperation? = nil
        if let imagePath = self.imagePathLocation(key: urlString) {
            if let image = UIImage(contentsOfFile: imagePath as String) {
                self.memoryCache.setObject(image, forKey: urlString)
                completionBlock(image, nil)
            }else {
                self.downloadImageOnlyFromWeb(urlString: urlString, progressBlock: progressBlock, completionBlock: completionBlock)
            }
        }else {
            self.downloadImageOnlyFromWeb(urlString: urlString, progressBlock: progressBlock, completionBlock: completionBlock)
        }
        
        return imageOperation
    }
    
    
    
    
    private func loadImageFromDisk(#urlString:NSString, completionBlock: LBCacheImageBlock) -> ImageOperation? {
        if let imagePath = self.imagePathLocation(key: urlString) {
            if let image = UIImage(contentsOfFile: imagePath as String) {
                self.memoryCache.setObject(image, forKey: urlString)
                completionBlock(image, nil)
            }else {
                let error = NSError(domain: kLBCacheErrorDomain, code: LBCacheImageError.CantCreateImage.rawValue, userInfo: [NSLocalizedDescriptionKey:kCantCreateImageDescription])
                completionBlock(nil,error)

            }
        }else {
            let error = NSError(domain: kLBCacheErrorDomain, code: LBCacheImageError.ImageNotFound.rawValue, userInfo: [NSLocalizedDescriptionKey:kImageNotFoundDescription])
            completionBlock(nil,error)
        }
        
        return nil
    }
    
    
    private func downloadImageFromWebOrLoadFromCache(#urlString:NSString,progressBlock: LBCacheProgressBlock?, completionBlock: LBCacheImageBlock) -> ImageOperation? {
        
        var operation = ImageOperation(urlString: urlString, progressBlock: { (percent) -> Void in
            if progressBlock != nil {
                progressBlock!(percent)
            }
            }) { [weak self] (image, error) -> Void in
                if error != nil {
                    if let image = self?.memoryCache.objectForKey(urlString) as? UIImage {
                        // try to load from memory caches
                        completionBlock(image, nil)
                    }
                    else {
                        // if not in memory cache try loading from disk
                        self?.loadImageFromDisk(urlString: urlString, completionBlock: completionBlock)
                    }
                }else {
                    // image loaded from web
                    if image != nil {
                        self?.memoryCache.setObject(image!, forKey: urlString)
                        completionBlock(image!, nil)
                    }
                }
        }
        
        self.imagesQueue.addOperation(operation)
        return operation
    }
    
    
    
    
    private func downloadImageOnlyFromWeb(#urlString:NSString,progressBlock: LBCacheProgressBlock?, completionBlock: LBCacheImageBlock) -> ImageOperation? {
        var operation = ImageOperation(urlString: urlString, progressBlock: { (percent) -> Void in
            if progressBlock != nil {
                progressBlock!(percent)
            }
        }) { [weak self] (image, error) -> Void in
            if error != nil {
                completionBlock(nil, error!)
            }else {
                if image != nil {
                    self?.memoryCache.setObject(image!, forKey: urlString)
                    completionBlock(image!, nil)
                }
            }
        }
        
        self.imagesQueue.addOperation(operation)
        return operation
    }
    
    
    
    
    
}


