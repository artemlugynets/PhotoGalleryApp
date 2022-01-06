//
//  LikesCollectionViewController.swift
//  PhotoGallery
//
//  Created by Artem Lugynets on 27.12.2021.
//

import UIKit
import Foundation

class LikesCollectionViewController: UICollectionViewController, UIGestureRecognizerDelegate {
    
    var photos = [UnsplashPhoto]()
    private var selectedLikedImages = [UIImage]()
    private var indexOfSelectedItem = [Int]()
    
    
    func readSavedPhotos() -> [UnsplashPhoto] {
            guard let data = UserDefaults.standard.value(forKey: "photosArray") as? Data else { return [] }
            let savedData = try? PropertyListDecoder().decode(Array<UnsplashPhoto>.self, from: data)
        photos = savedData ?? []
        return savedData ?? []
    }
    
    func savePhotos() {
        UserDefaults.standard.set(try? PropertyListEncoder().encode(photos), forKey: "photosArray")
    }
    
    private lazy var trashBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(trashBarButtonTapped))
    }()
    private lazy var actionBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(actionBarButtonTapped))
    }()
    
    private var numberOfSelectedPhotos: Int {
        return collectionView.indexPathsForSelectedItems?.count ?? 0
    }
    
    private let enterSearchTermLabel: UILabel = {
        let label = UILabel()
        label.text = "You haven't add a photos yet"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        addLongPressGR()
        setupEnterLabel()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        readSavedPhotos()
    }
    
    // MARK: - Setup GR (Drag & Drop)
    
    func addLongPressGR() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressGR(recognizer:)))
        gesture.minimumPressDuration = 0.5
        gesture.delaysTouchesBegan = true
        gesture.delegate = self
        self.collectionView.addGestureRecognizer(gesture)
    }
    
    @objc func longPressGR(recognizer: UILongPressGestureRecognizer) {
        switch recognizer.state {
        case .began:
            guard let targetIndexPath = collectionView.indexPathForItem(at: recognizer.location(in: collectionView)) else {
                return
            }
            collectionView.beginInteractiveMovementForItem(at: targetIndexPath)
        case .changed:
            collectionView.updateInteractiveMovementTargetPosition(recognizer.location(in: collectionView))
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
    
    // MARK: - Setup UI Elements
    
    private func setupCollectionView() {
        collectionView.register(LikesCollectionViewCell.self, forCellWithReuseIdentifier: LikesCollectionViewCell.reuseId)
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.allowsMultipleSelection = true
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.minimumInteritemSpacing = 1
        layout.minimumLineSpacing = 1
    }
    
    private func setupEnterLabel() {
        collectionView.addSubview(enterSearchTermLabel)
        enterSearchTermLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor).isActive = true
        enterSearchTermLabel.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: 50).isActive = true
    }
    
    private func setupNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.text = "FAVORITES"
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .black
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: titleLabel)
        navigationItem.rightBarButtonItems = [trashBarButtonItem, actionBarButtonItem]
        trashBarButtonItem.isEnabled = false
        actionBarButtonItem.isEnabled = false
    }
    @objc private func trashBarButtonTapped() {
        for index in indexOfSelectedItem {
            photos.remove(at: index)
        }
        savePhotos()
        collectionView.reloadData()
        refreshLikedPhotos()
    }
    @objc private func actionBarButtonTapped(sender: UIBarButtonItem) {
        let shareController = UIActivityViewController(activityItems: selectedLikedImages, applicationActivities: nil)
    
        shareController.completionWithItemsHandler = { _, bool, _, _ in
            if bool {
                self.refreshLikedPhotos()
            }
            
        }
        shareController.popoverPresentationController?.barButtonItem = sender
        shareController.popoverPresentationController?.permittedArrowDirections = .any
        present(shareController, animated: true, completion: nil)
        
    }
    
    func refreshLikedPhotos() {
        self.selectedLikedImages.removeAll()
        self.indexOfSelectedItem.removeAll()
        self.collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
        updateNavButtonState()
    }
    private func updateNavButtonState() {
        trashBarButtonItem.isEnabled = numberOfSelectedPhotos > 0
        actionBarButtonItem.isEnabled = numberOfSelectedPhotos > 0
    }
    
    // MARK: - UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        enterSearchTermLabel.isHidden = photos.count != 0
        return photos.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LikesCollectionViewCell.reuseId, for: indexPath) as! LikesCollectionViewCell
        let unsplashPhoto = photos[indexPath.item]
        cell.unsplashPhoto = unsplashPhoto
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let item = photos.remove(at: sourceIndexPath.row)
        photos.insert(item, at: destinationIndexPath.row)
        savePhotos()
    }
        
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateNavButtonState()
        let cell = collectionView.cellForItem(at: indexPath) as! LikesCollectionViewCell
        guard let image = cell.myImageView.image else { return }
        selectedLikedImages.append(image)
        indexOfSelectedItem.append(indexPath.item)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateNavButtonState()
        let cell = collectionView.cellForItem(at: indexPath) as! LikesCollectionViewCell
        guard let image = cell.myImageView.image else { return }
        if let index = selectedLikedImages.firstIndex(of: image) {
            selectedLikedImages.remove(at: index)
            indexOfSelectedItem.remove(at: index)
        }
    }
}

    // MARK: - UICollectionViewDelegateFlowLayout
    extension LikesCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width
        return CGSize(width: width/3 - 1, height: width/3 - 1)
    }
}


