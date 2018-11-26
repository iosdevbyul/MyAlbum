//
//  TestCollectionViewCell.swift
//  07082018
//
//  Created by COMATOKI on 2018-07-08.
//  Copyright © 2018 COMATOKI. All rights reserved.
//

import UIKit

class AlbumCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var cellImage: UIImageView! // display a lastest image in each album
    
    @IBOutlet weak var albumNameLabel: UILabel! // display a name of album
    
    @IBOutlet weak var countLabel: UILabel! // display number of images
    
}
