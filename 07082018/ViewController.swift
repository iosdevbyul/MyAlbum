//
//  ViewController.swift
//  07082018
//
//  Created by COMATOKI on 2018-07-08.
//  Copyright © 2018 COMATOKI. All rights reserved.
//

import UIKit
import Photos

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
    
    // MARK: - Properties
    // CollectionView to display albums
    @IBOutlet weak var albumCollectionView: UICollectionView!
    
    // Identifier for transition to AlbumPhotosViewController
    let segueIdentifier: String = "gotoPhotoList"
    
    // a cell's index selected by a user
    var selectedCellIndex: Int = 0
    
    // container to store collectionView's size
    var cellSize: CGSize?
    
    // Information of albums
    var albumNameList: [String] = []
    var albumCountList: [Int] = []
    var albumCollectionList: [PHAssetCollection] = []

    // Properties for photos
    var fetchResult: [PHFetchResult<PHAsset>] = []
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    // Class for an album
    class AlbumModel {
        let name: String
        let count: Int
        let collection: PHAssetCollection
        init(name: String, count: Int, collection: PHAssetCollection) {
            self.name = name
            self.count = count
            self.collection = collection
        }
    }
    
    // MARK: - Load Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.title = "Album"
        
        checkAuthorizationStatus()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        requestCollection()
        albumCollectionView.reloadData()
        navigationController?.setToolbarHidden(true, animated: false)
        PHPhotoLibrary.shared().register(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - CollectionView Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return albumNameList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {


        
        // Define cell to reuse
        guard let cell: AlbumCollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath) as? AlbumCollectionViewCell else {
            return UICollectionViewCell()
        }

        if albumNameList.count <= 0 {
            return UICollectionViewCell()
        }

        // Get an appropriate image from fetchResult
        let asset: PHAsset = fetchResult[indexPath.item].object(at: 0)

        // Define size of a cell and locations of items
        guard let cellWidth = self.cellSize?.width else {
            return cell
        }

        cell.cellImage.frame = CGRect(x: 0, y: 0, width: cellWidth, height: cellWidth)
        cell.cellImage.clipsToBounds = true
        cell.albumNameLabel.frame = CGRect(x: 5, y: cellWidth + 5, width: cellWidth - 10, height: 20)
        cell.albumNameLabel.text = self.albumNameList[indexPath.item]
        cell.countLabel.frame = CGRect(x: 5, y: cellWidth + 30  , width: cellWidth - 10, height: 20)
        cell.countLabel.text = "\(albumCountList[indexPath.item])"

        // Adjust image to cellImage
        OperationQueue().addOperation {
            self.imageManager.requestImage(for: asset,
                                           targetSize: CGSize(width: cellWidth, height: cellWidth),
                                           contentMode: .aspectFill,
                                           options: nil,
                                           resultHandler: { image, _ in
                OperationQueue.main.addOperation {
                    cell.cellImage.image = image
                }
            })
        }




        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let orientation = UIApplication.shared.statusBarOrientation
        var screenWidth: CGFloat = 0
        var cellSize: CGSize = CGSize()
        
        //landscape
        if ((orientation == .landscapeLeft) || (orientation == .landscapeRight)) {
            screenWidth = UIScreen.main.bounds.height
        } else { //portrait
            screenWidth = UIScreen.main.bounds.width
        }
        let appropriateCellWidth = (screenWidth - (screenWidth * 0.12)) / 2
        let appropriateCellHeight = appropriateCellWidth + 50
        
        cellSize = CGSize(width: appropriateCellWidth, height: appropriateCellHeight)
        
        self.cellSize = cellSize
        return cellSize
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedCellIndex = indexPath.item
        performSegue(withIdentifier: segueIdentifier, sender: nil)
    }

    // MARK: Photo Methods
    // Referenced by https://stackoverflow.com/questions/36713164/list-all-photo-albums-in-ios
    func requestCollection() {
        self.fetchResult.removeAll()
        self.albumNameList.removeAll()
        self.albumCountList.removeAll()
        self.albumCollectionList.removeAll()
        
        var album: [AlbumModel] = [AlbumModel]()
        let userAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)

        // To detect empty albums
        var originalNewAlbum: [AlbumModel] = [AlbumModel]()
        
        userAlbums.enumerateObjects { object, index, stop in
            let obj: PHAssetCollection = object

            var assetCount = obj.estimatedAssetCount
            
            if assetCount == NSNotFound {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
                assetCount = PHAsset.fetchAssets(in: obj, options: fetchOptions).count
            }
            
            guard let localizedTitle = obj.localizedTitle else {
                return
            }
            let newAlbum = AlbumModel(name: localizedTitle, count: assetCount, collection:obj)
            originalNewAlbum.append(newAlbum)
            
            if (assetCount > 0) {
                let newAlbum = AlbumModel(name: localizedTitle, count: assetCount, collection:obj)
                album.append(newAlbum)
            }
        }
            
        let fetchOption = PHFetchOptions()
        fetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        for item in album {
            albumNameList.append(item.name)
            albumCountList.append(item.count)
            albumCollectionList.append(item.collection)
        }
        
        for i in 0..<originalNewAlbum.count {
            // if the stored album is not empty, executes the process to append
            if originalNewAlbum[i].count != 0 {
                self.fetchResult.append(PHAsset.fetchAssets(in: userAlbums.object(at: i), options: fetchOption))
            }
        }
    }
    
    private func fetchSmartCollections(with: PHAssetCollectionType, subtypes: [PHAssetCollectionSubtype]) -> [PHAssetCollection] {
        var collections:[PHAssetCollection] = []
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        
        for subtype in subtypes {
            if let collection = PHAssetCollection.fetchAssetCollections(with: with, subtype: subtype, options: options).firstObject {
                collections.append(collection)
            }
        }
        return collections
    }
    
    func checkAuthorizationStatus() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        
        switch photoAuthorizationStatus {
        case .authorized:
//            self.requestCollection()
//            OperationQueue.main.addOperation {
//                self.albumCollectionView.reloadData()
//            }
            print("authorized")
        case .denied:
            print("denied")
        case .notDetermined:
            print("notDetermined")
            PHPhotoLibrary.requestAuthorization({ (status) in
                switch status {
                case .authorized:
                    print("authorized")
//                    self.requestCollection()
//                    OperationQueue.main.addOperation {
//                        self.albumCollectionView.reloadData()
//                    }
                case .denied:
                    print("denied")
                default: break
                }
            })
        case .restricted:
            print("restricted")
        }
    }
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == segueIdentifier {
            guard let nextViewController = segue.destination as? AlbumPhotosViewController else {
                return
            }
            nextViewController.fetchResult = self.fetchResult[selectedCellIndex]
            nextViewController.navigationItem.title = albumNameList[selectedCellIndex]
            nextViewController.thisAssetCollection = albumCollectionList[selectedCellIndex]
        }
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("photoLibraryDidChange")
        
        self.requestCollection()
        OperationQueue.main.addOperation {
            self.albumCollectionView.reloadData()
        }
    }
}
