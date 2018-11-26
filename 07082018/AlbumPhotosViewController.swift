//
//  AlbumPhotosViewController.swift
//  07082018
//
//  Created by COMATOKI on 2018-07-09.
//  Copyright © 2018 COMATOKI. All rights reserved.
//

import UIKit
import Photos

class AlbumPhotosViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, PHPhotoLibraryChangeObserver {
    
    // MARK: - Properties
    // CollectionView to display images
    @IBOutlet weak var assetCollectionView: UICollectionView!
    
    var thisAssetCollection: PHAssetCollection?
    
    // selected Cell by a user
    var selectedCellIndex: Int = 0
    
    // Properties for photos
    var fetchResult: PHFetchResult<PHAsset>?
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    
    // Identifier
    let cellIdentifier: String = "photoCell"
    let segueIdentifier: String = "gotoPhoto"
    
    // Cell size
    var cellSize: CGSize?
    
    var selectButton: UIBarButtonItem?
    var selectedMode: Bool = true
    var selectedAssets: [PHAsset] = []
    var selectedAsset: PHAsset?
    var selectedAssetIndex: [Int] = []
    var selectedIndexPath: [IndexPath] = []

    @IBOutlet weak var shareButton: UIBarButtonItem!
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBOutlet weak var orderButton: UIBarButtonItem!
    
    var initTitle: String?
    
    var isLatest: Bool = true
    
    // MARK: - Load Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.

        setSelectButton()
        initTitle = self.navigationItem.title
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func setSelectButton() {
        selectButton = UIBarButtonItem(title: "선택", style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.selectPhoto(_:)))
        self.navigationItem.rightBarButtonItem = selectButton
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        deleteButton.isEnabled = false
        shareButton.isEnabled = false
        
        selectedMode = false
        
        navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
    }

    // MARK: - Actions
    @IBAction func changeOrderOfPhotos(_ sender: Any) {
        reorderPhotos()
    }
    
    func reorderPhotos() {
        let fetchOption: PHFetchOptions = PHFetchOptions()
        
        if isLatest {
            orderButton.title = "과거순"
            isLatest = false
            fetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        } else {
            orderButton.title = "최신순"
            isLatest = true
            fetchOption.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        }
        
        guard let thisAssetCollection = thisAssetCollection else {
            return
        }
        self.fetchResult = PHAsset.fetchAssets(in: thisAssetCollection, options: fetchOption)
        OperationQueue.main.addOperation {
            self.assetCollectionView.reloadData()
        }
    }

    @IBAction func sendPhotos(_ sender: Any) {
        // Prepare images the user selected to share
        var imagesToShare: [UIImage] = []
                
        let options : PHImageRequestOptions = PHImageRequestOptions()
        options.resizeMode = PHImageRequestOptionsResizeMode.exact
        options.isSynchronous = true
        
        for i in 0..<self.selectedAssets.count {
            imageManager.requestImage(for: self.selectedAssets[i],
                                      targetSize: CGSize(width: selectedAssets[i].pixelWidth, height: selectedAssets[i].pixelHeight),
                                      contentMode: .aspectFit,
                                      options: options, resultHandler: {
                                        image, _ in
                                        guard let image: UIImage = image else {
                                            return
                                        }
                                        imagesToShare.append(image)
            })
        }
        // Create UIActivityViewController
        let activityViewController = UIActivityViewController(activityItems: imagesToShare, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { (activity, success, items, error) in
//            activity - UIActivitytype
//            success - bool
//            items - [Any]
//            error - Error
            if success {
                // Reset selectButton
                self.selectedMode = true
                self.resetSelectButton()
                
                // Reset Cells to remove black background
                OperationQueue.main.addOperation {
                    self.assetCollectionView.reloadData()
                }
            }
        }
        self.present(activityViewController, animated: true, completion: nil)

    }

    @IBAction func deletePhoto(_ sender: Any) {
        deletePhotos()
    }
    
    func deletePhotos() {
        PHPhotoLibrary.shared().performChanges({PHAssetChangeRequest.deleteAssets(self.selectedAssets as NSArray)}, completionHandler:
            {(success, error) in
                if success {
                    OperationQueue.main.addOperation {
                        self.resetSelectButton()
                    }
                } else {
                    print("\(String(describing: error?.localizedDescription))")
                }
            })
    }
    
    @objc func selectPhoto(_ sender: UIBarButtonItem) {
        resetSelectButton()
    }
    
    func resetSelectButton() {
        selectedMode = !selectedMode
        if selectedMode == true {
            selectButton?.title = "취소"
            self.title = "항목 선택"
            self.navigationItem.setHidesBackButton(true, animated:true);
            assetCollectionView.allowsMultipleSelection = true
        } else {
            self.navigationItem.title = initTitle
            selectButton?.title = "선택"
            self.navigationItem.setHidesBackButton(false, animated:true);
            
            self.assetCollectionView.allowsMultipleSelection = false
            
            self.deleteButton.isEnabled = false
            self.shareButton.isEnabled = false
        }
        self.selectedAssets.removeAll()
        self.selectedAssetIndex.removeAll()
//        self.assetCollectionView.reloadItems(at: self.selectedIndexPath)
        self.selectedIndexPath.removeAll()
    }

    // MARK: - CollectionView Methods
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchResult?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell: ListOfPhotosInAlbumCell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? ListOfPhotosInAlbumCell else {
            return UICollectionViewCell()
        }
        
        guard let fetchResult = fetchResult else {
            return cell
        }
        
        guard let size = cellSize?.width else {
            return cell
        }
        
        var asset: PHAsset = fetchResult.object(at: indexPath.item)

        asset = fetchResult.object(at: indexPath.item)

        cell.photoImage.frame = CGRect(x: 3, y: 3, width: size-6, height: size-6)
        cell.photoImage.clipsToBounds = true
        if isThisSelectedItem(self.selectedAssetIndex, indexPath.item) {
            cell.backgroundColor = UIColor.black
        } else {
            cell.backgroundColor = UIColor.white
        }
        
        OperationQueue().addOperation {
            self.imageManager.requestImage(for: asset,
                                           targetSize: CGSize(width: size-5 , height: size-5),
                                           contentMode: .aspectFill,
                                           options: nil,
                                           resultHandler: {
                                            image, _ in
                                            OperationQueue.main.addOperation {
                                                cell.photoImage?.image = image
                                                
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
        if (orientation == .landscapeLeft || orientation == .landscapeRight) {
            screenWidth = UIScreen.main.bounds.height
        } else { //portrait
            screenWidth = UIScreen.main.bounds.width
        }
        let appropriateCellWidth = (screenWidth - 50)/3
        cellSize = CGSize(width: appropriateCellWidth, height: appropriateCellWidth)
        
        self.cellSize = cellSize
        return cellSize
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // If a user has clicked the select button
        if selectedMode {
            // A user has selected an item that is already selected by the user
            if isThisSelectedItem(self.selectedAssetIndex, indexPath.item) {
                let index: Int = getIndexFromSelctedItem(self.selectedAssetIndex,indexPath.item)
                if(index != -1) {
                    selectedAssetIndex.remove(at: index)
                    selectedAssets.remove(at: index)
                    selectedIndexPath.remove(at: index)
                }
                if selectedAssetIndex.count == 0 {
                    deleteButton.isEnabled = false
                    shareButton.isEnabled = false
                }
            } else{
                selectedAssetIndex.append(indexPath.item)
                guard let fetchRes = fetchResult else {
                    return
                }
                selectedAsset = fetchRes.object(at: indexPath.item)
                guard let selectAsset = selectedAsset else {
                    return
                }
                selectedAssets.append(selectAsset)
                selectedIndexPath.append(indexPath)
                deleteButton.isEnabled = true
                shareButton.isEnabled = true
            }

            if self.selectedAssetIndex.count == 0 {
                self.title = "항목 선택"
            } else {
                self.title = "\(self.selectedAssetIndex.count)"+"장 선택"
            }
            collectionView.reloadItems(at: [indexPath])
        } else {
            // If a user didn't click the select button
            selectedCellIndex = indexPath.item
            performSegue(withIdentifier: segueIdentifier, sender: self)
        }
    }
    
    // MARK: - Getting Selected Item
    func isThisSelectedItem(_ selectedAssetIndex: [Int], _ currentItemIndex: Int) -> Bool {
        for i in 0..<selectedAssetIndex.count {
            if selectedAssetIndex[i] == currentItemIndex {
                return true
            }
        }
        return false
    }
    
    func getIndexFromSelctedItem(_ selectedAssetIndex: [Int], _ currentItemIndex: Int) -> Int {
        var returnIndex: Int = -1
        for i in 0..<selectedAssetIndex.count {
            if selectedAssetIndex[i] == currentItemIndex {
                returnIndex = i
                return returnIndex
            }
        }
        return returnIndex
    }
    
    // MARK: - A Prepare Method
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if !selectedMode {
            if segue.identifier == segueIdentifier {
                guard let nextViewController:PhotoViewController = segue.destination as? PhotoViewController else {
                    return
                }

                guard let fetchResult = fetchResult else {
                    return
                }
                nextViewController.selectedAsset = fetchResult.object(at: selectedCellIndex)
            }
        }
        
    }
    
    // MARK: - photoLibraryDidChange
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        guard let fetchResult = fetchResult else {
            return
        }
        
        guard let changes = changeInstance.changeDetails(for: fetchResult) else {
            return
        }
        
        self.fetchResult = changes.fetchResultAfterChanges

        OperationQueue.main.addOperation {
            self.assetCollectionView.reloadData()
        }
    }
}
