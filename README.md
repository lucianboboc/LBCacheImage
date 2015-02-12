# LBCacheImage

LBCacheImage is an image caching library for iOS
 
How to use this library:
=======
- drag the <code>LBCacheImage</code> folder to your project.
- import the <code>CommonCrypto.h</code> header to the Objective C bridging header file because the NSString class extension is using CommonCrypto for hashing.


This library offer:
=======
- asynchronous image download;
- cache support (memory and disk) with the option to set the days to keep the cache on disk;
- option to get the local path to an image.
- create <code>MD5,SHA1,SHA256</code> hash.
 
 
Classes and extensions to use:
======= 
I. UIImageView class extension:
-------
- this UIImageView class extension offers the option to set a URL string of the image location on the server;
- the image is downloaded asynchronous in the background;
- the image is saved on the disk in the caches directory;

Methods to use:
- <code>setImageWithURLString:placeholderImage:</code> - download and cache the image
- <code>setImageWithURLString:placeholderImage:options:</code> - download and cache the image
- <code>setImageWithURLString:placeholderImage:options:completionBlock:</code> - download, cache and return the image
- <code>imageForURLString:</code> - search the UIImage directly in cache (memory or disk), nil is returned if not found


There are 3 <code>LBCacheImageOptions</code> to use:
- <code>.Default</code> - it first search the memory cache, if not found it search on the disk, if not found it will download asynchronous and cache it
- <code>.ReloadFromWebOrCache</code> - it will try to reload the image from the web, if it fails it will load from local cache
- <code>.LoadOnlyFromCache</code> - it will only search in memory and on the disk



II. LBCacheImage:
-------
- this class is used by the UIImageView class extension for the download but you can use it directly.

Options to use:
- <code>kDaysToKeepCache</code> - stores the days to keep the images in cache
- <code>kDefaultHashType</code> - stores the hash type declared in the <code>NSString</code> class extension and it has 3 values: <code>.MD5, .SHA1, .SHA256</code>
 
Methods to use:
- <code>imagePathLocationForURLString:</code> - a string with the local path location of the image saved on disk or nil if the image for the URLString is not found
- <code>downloadImageFromURLString:options:progressBlock:completionBlock:</code> - same as UIImageView class extension, cache and return the image
- <code>imageForURLString:</code> - same as UIImageView class extension, search the UIImage directly in cache (memory or disk), nil is returned if not found

 
III. NSString class extension:
-------
- use this class extension to get hash value from a string.
- there are 3 options available, <code>MD5, SHA1 and SHA256</code>

Methods to use:
- <code>lbHashMD5</code> - create an MD5 hash
- <code>lbHashSHA1</code> - create an SHA1 hash
- <code>lbHashSHA256</code> - create an SHA256 hash
- <code>lbHashWithType:</code> - create a hash using the 3 available options
 

LICENSE
=======

This content is released under the MIT License https://github.com/lucianboboc/LBCacheImage/blob/master/LICENSE.md
 

Enjoy!
