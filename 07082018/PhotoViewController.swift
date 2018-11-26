//
//  PhotoViewController.swift
//  07082018
//
//  Created by COMATOKI on 2018-07-09.
//  Copyright © 2018 COMATOKI. All rights reserved.
//

import UIKit
import Photos

class PhotoViewController: UIViewController, PHPhotoLibraryChangeObserver, UIScrollViewDelegate {
    
    // MARK: - Properties
    @IBOutlet weak var favoriteButton: UIBarButtonItem!
    @IBOutlet weak var photoScrollView: UIScrollView!
    @IBOutlet weak var displayPhotoImageView: UIImageView!
    var touchGesture: UITapGestureRecognizer = UITapGestureRecognizer()
    var isImageFavorite: Bool = false
    var selectedAsset: PHAsset?
    let imageManager: PHCachingImageManager = PHCachingImageManager()
    var isShowingAllItems: Bool?
    var isClickedDeleteButton: Bool = false
    
    // MARK: - Load Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        isShowingAllItems = true

        setScrollView()
        setImageView()
        addGestureToThisView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        guard let favorite = selectedAsset?.isFavorite else {
            return
        }
        
        self.isImageFavorite = favorite
        
        setNaviTitle()
        setImage()
        setFavoriteButtonTint()
        
        //Set navigationController's item to show
        isShowingAllItems = true
        navigationController?.setToolbarHidden(false, animated: false)
        navigationController?.navigationBar.isHidden = false
        
        PHPhotoLibrary.shared().register(self)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    func setScrollView() {
        photoScrollView.maximumZoomScale = 3
        photoScrollView.minimumZoomScale = 1
        photoScrollView.delegate = self
        photoScrollView.isScrollEnabled = true
        photoScrollView.contentMode = .scaleAspectFit
    }
    
    func setImageView() {
        displayPhotoImageView.contentMode = .scaleAspectFit
    }
    
    func addGestureToThisView() {
        touchGesture = UITapGestureRecognizer(target: self, action: #selector(touchImage))
        self.view.addGestureRecognizer(touchGesture)
    }
    
    
    func setFavoriteButtonTint() {
        if self.isImageFavorite {
            //red
            OperationQueue.main.addOperation{
                self.favoriteButton.tintColor = UIColor.red
            }
        } else {
            //black
            OperationQueue.main.addOperation{
                self.favoriteButton.tintColor = UIColor.black
            }
        }
    }
    
    // Referenced by https://stackoverflow.com/questions/38626004/add-subtitle-under-the-title-in-navigation-bar-controller-in-xcode
    func setNaviTitle() {
        guard let selectedAsset = selectedAsset else {
            return
        }
        
        guard let creationDate = selectedAsset.creationDate else {
            return
        }
        
        // Date
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let date = dateFormatter.string(from: creationDate)
        
        // Time
        dateFormatter.dateFormat = "a hh:mm:ss"
        let time = dateFormatter.string(from: creationDate)
        
        // Date Label
        let dateLabel: UILabel = UILabel()
        dateLabel.textAlignment = .center
        dateLabel.text = date
        dateLabel.textColor = UIColor.black
        dateLabel.font = UIFont.boldSystemFont(ofSize: 15)
        dateLabel.sizeToFit()
        
        //Time Label
        let timeLabel: UILabel = UILabel()
        timeLabel.textAlignment = .center
        timeLabel.text = time
        timeLabel.textColor = UIColor.gray
        timeLabel.font = UIFont.boldSystemFont(ofSize: 10)
        timeLabel.sizeToFit()

        // Title View
        let titleView = UIView(frame: CGRect(x: 0, y: 0, width: max(dateLabel.frame.size.width, timeLabel.frame.size.width), height: 40))
        
        titleView.addSubview(dateLabel)
        titleView.addSubview(timeLabel)

        dateLabel.frame = CGRect(x: (titleView.frame.size.width/2) - (dateLabel.frame.size.width/2), y: 0, width: dateLabel.frame.size.width, height: dateLabel.frame.size.height)
        timeLabel.frame = CGRect(x: (titleView.frame.size.width/2) - (timeLabel.frame.size.width/2), y: dateLabel.frame.size.height, width: timeLabel.frame.size.width, height: timeLabel.frame.size.height)
        
        self.navigationItem.titleView = titleView
    }
    
    func setImage() {
        guard let asset = selectedAsset else {
            return
        }
        
        imageManager.requestImage(for: asset, targetSize: CGSize(width: displayPhotoImageView.frame.width , height: displayPhotoImageView.frame.height), contentMode: .aspectFit, options: nil, resultHandler: {
            image, _ in
            self.displayPhotoImageView.image = image
        })
    }
    
    // MARK: - Actions
    @IBAction func clickFavoriteButton(_ sender: Any) {
        setFavoriteStatus()
    }
    
    @IBAction func clickShareButton(_ sender: Any) {
        createUIActivityViewController()
    }
    
    @IBAction func clickDeleteButton(_ sender: Any) {
        isClickedDeleteButton = true
        removePhoto()
    }

    func removePhoto() {
        guard let asset:PHAsset = self.selectedAsset else {
            return
        }
        PHPhotoLibrary.shared().performChanges({PHAssetChangeRequest.deleteAssets([asset] as NSArray)}, completionHandler: {(success, error) in
            OperationQueue.main.addOperation {
                self.navigationController?.popViewController(animated: true)
            }
        })
    }

    func setFavoriteStatus()  {
        guard let selectedAsset: PHAsset = self.selectedAsset else {
            return
        }

        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest(for: selectedAsset).isFavorite = !self.isImageFavorite}, completionHandler: {(success, error) in
                if success {
                    self.isImageFavorite = !self.isImageFavorite
                } else {
                    print("\(String(describing: error?.localizedDescription))")
                }
        })
    }

    // MARK: - activityViewController Methods
    func createUIActivityViewController() {
        guard let asset: PHAsset = self.selectedAsset else {
            return
        }
        
        var imageToShare: [UIImage] = []
        
        let options : PHImageRequestOptions = PHImageRequestOptions()
        options.resizeMode = PHImageRequestOptionsResizeMode.exact
        options.isSynchronous = true

        imageManager.requestImage(for: asset, targetSize: CGSize(width: asset.pixelWidth , height: asset.pixelHeight), contentMode: .aspectFit, options: options, resultHandler: {
            image, _ in
            guard let img: UIImage = image else {
                return
            }
            imageToShare.append(img)
        })
        
        let activityViewController = UIActivityViewController(activityItems: imageToShare, applicationActivities: nil)
        activityViewController.completionWithItemsHandler = { (activity, success, items, error) in
        }
        self.present(activityViewController, animated: true, completion: nil)
    }
    
    // MARK: - photoLibraryDidChange
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        if isClickedDeleteButton {
            dismiss(animated: true, completion: nil)
        } else {
            
            let changes = changeInstance.changeDetails(for: selectedAsset!)
            selectedAsset = changes?.objectAfterChanges
            
            self.setFavoriteButtonTint()
        }
    }

    // MARK: - A ScrollView Method
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return displayPhotoImageView
    }
    
    func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        isShowingAllItems = false
        
        guard let isShowing: Bool = isShowingAllItems else {
            return
        }
        
        dismissOrShowItemsOnViewController(isShowing)
    }

    // MARK: - A Tap Gesture Recognizer method
    @objc func touchImage(_ sender: Any) {
        guard let isShowing: Bool = isShowingAllItems else {
            return
        }
        dismissOrShowItemsOnViewController(!isShowing)
        
        isShowingAllItems = !isShowing
    }
    
    func dismissOrShowItemsOnViewController(_ isShowing: Bool) {
        navigationController?.setToolbarHidden(!isShowing, animated: false)
        navigationController?.navigationBar.isHidden = !isShowing

    }
}


