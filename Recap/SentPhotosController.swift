//
//  CollectionViewController.swift
//  Recap
//
//  Created by Alex Brashear on 7/30/17.
//  Copyright © 2017 memailer. All rights reserved.
//

import UIKit
import Reusable

class SentPhotosController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var gridCollectionView: UICollectionView!
    var gridLayout: SentPhotosLayout!
    var didTapPhoto: ((Photo) -> Void)?
    
    var photos: [Photo]? {
        didSet {
            gridCollectionView.reloadData()
        }
    }
    
    var imageProvider: ImageProvider?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        gridLayout = SentPhotosLayout()
        gridCollectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout: gridLayout)
        gridCollectionView.backgroundColor = .white
        gridCollectionView.showsVerticalScrollIndicator = false
        gridCollectionView.showsHorizontalScrollIndicator = false
        self.view.addSubview(gridCollectionView)
        gridCollectionView.translatesAutoresizingMaskIntoConstraints = false
        gridCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 1).isActive = true
        gridCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -1).isActive = true
        gridCollectionView.topAnchor.constraint(equalTo: view.topAnchor, constant: 1).isActive = true
        gridCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        gridCollectionView.alwaysBounceVertical = true

        // Register cell classes
        gridCollectionView.register(cellType: PhotoItem.self)
        
        gridCollectionView.dataSource = self
        gridCollectionView.delegate = self
    }

    // MARK: UICollectionViewDataSource

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard indexPath.row < (photos?.count ?? 0), let photo = photos?[indexPath.row] else {
            return UICollectionViewCell()
        }
        let cell = collectionView.dequeueReusableCell(for: indexPath) as PhotoItem
        cell.imageProvider = imageProvider
        cell.photo = photo
        return cell
    }

    // MARK: UICollectionViewDelegate

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.row < (photos?.count ?? 0), let photo = photos?[indexPath.row] else { return }
        didTapPhoto?(photo)
    }
}
