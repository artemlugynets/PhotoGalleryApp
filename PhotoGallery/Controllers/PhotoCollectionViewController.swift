//
//  PhotoCollectionViewController.swift
//  PhotoGallery
//
//  Created by Artem Lugynets on 24.12.2021.
//

import UIKit

enum Section: Int, CaseIterable {
    case main
}


class PhotoCollectionViewController: UICollectionViewController, UIGestureRecognizerDelegate {
    
    
    //MARK: LayoutDataSource:
    lazy var dataSource: UICollectionViewDiffableDataSource<Section, UnsplashPhoto> =  {
        let diffablDataSource = UICollectionViewDiffableDataSource<Section, UnsplashPhoto>(collectionView: collectionView) { (collectionView, indexPath, itemIdentifier) -> UICollectionViewCell in
            
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotosCell.reuseId, for: indexPath) as? PhotosCell else { fatalError("Cannot create the cell") }
            let unsplashedPhoto = self.photos[indexPath.item]
            cell.unsplashPhoto = unsplashedPhoto
            return cell
        }
        return diffablDataSource
    }()
    
    var networkDataFetcher = NetworkDataFetcher()
    
    private var timer: Timer?
    
    private var photos = [UnsplashPhoto]()
    private var selectedImages = [UIImage]()
    
    
//    private let itemsPerRow: CGFloat = 2 // UICollectionViewDelegateFlowLayout
//    private let sectionInserts = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20) // UICollectionViewDelegateFlowLayout
    
    private lazy var addBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addBarButtonTapped))
    }()
    private lazy var actionBarButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(actionBarButtonTapped))
    }()
    
    private var numberOfSelectedPhotos: Int {
        return collectionView.indexPathsForSelectedItems?.count ?? 0
    }
    
    private let enterSearchTermLabel: UILabel = {
        let label = UILabel()
        label.text = "Please enter search term above..."
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        return spinner
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupNavigationBar()
        setupSearchBar()
        updateNavButtonState()
        setupEnterLabel()
        setupSpinner()
    }
    
    // MARK: - Gesture recognizer
    
    func addGR() {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressPreview(recognizer:)))
        gesture.minimumPressDuration = 0.5
        gesture.delaysTouchesBegan = true
        gesture.delegate = self
        self.collectionView.addGestureRecognizer(gesture)
    }
    
    @objc func longPressPreview(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state != UILongPressGestureRecognizer.State.began {
            let p = recognizer.location(in: self.collectionView)
            let indexPath = self.collectionView.indexPathForItem(at: p)
            
            if let PreviewVC = self.storyboard?.instantiateViewController(withIdentifier: "PreviewCollectionViewController") as? PreviewCollectionViewController {
                let cell = collectionView.cellForItem(at: indexPath!) as! PhotosCell
                guard let image = cell.photoImageView.image else { return }
                PreviewVC.previewPhoto = image
                self.navigationController?.present(PreviewVC, animated: true, completion: nil)
//                self.navigationController?.pushViewController(PreviewVC, animated: true)
            }
        }
    }
    
    private func updateNavButtonState() {
        addBarButtonItem.isEnabled = numberOfSelectedPhotos > 0
        actionBarButtonItem.isEnabled = numberOfSelectedPhotos > 0
    }
    
    func refresh() {
        self.selectedImages.removeAll()
        self.collectionView.selectItem(at: nil, animated: true, scrollPosition: [])
        updateNavButtonState()
    }
    
    // MARK: - Navigation Item Actions
    @objc private func addBarButtonTapped() {
        let selectedPhotos = collectionView.indexPathsForSelectedItems?.reduce([], { (photosss, indexPath) -> [UnsplashPhoto] in
            var mutablePhotos = photosss
            let photo = photos[indexPath.item]
            mutablePhotos.append(photo)
            return mutablePhotos
        })
        let alertController = UIAlertController(title: "", message: "\(selectedPhotos!.count) фото будут добавлены в альбом", preferredStyle: .alert)
        let add = UIAlertAction(title: "Добавить", style: .default) { (action) in
            let tabbar = self.tabBarController as! MainTabBarController
            let navVC = tabbar.viewControllers?[1] as! UINavigationController
            let likesVC = navVC.topViewController as! LikesCollectionViewController
            likesVC.readSavedPhotos()
            likesVC.photos.append(contentsOf: selectedPhotos ?? [])
            likesVC.savePhotos()
            likesVC.collectionView.reloadData()
            
            self.refresh()
        }
        let cancel = UIAlertAction(title: "Отменить", style: .cancel) { (action) in
        }
        alertController.addAction(add)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
    @objc private func actionBarButtonTapped(sender: UIBarButtonItem) {
        let shareController = UIActivityViewController(activityItems: selectedImages, applicationActivities: nil)
        shareController.completionWithItemsHandler = { _, bool, _, _ in
            if bool {
                self.refresh()
            }
        }
        shareController.popoverPresentationController?.barButtonItem = sender
        shareController.popoverPresentationController?.permittedArrowDirections = .any
        present(shareController, animated: true, completion: nil)
    }

    // MARK: - Setup UI Elements
    private func setupCollectionView() {
        self.collectionView!.register(PhotosCell.self, forCellWithReuseIdentifier: PhotosCell.reuseId)
        collectionView.layoutMargins = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.allowsMultipleSelection = true
        self.collectionView.dataSource = self.dataSource
        self.collectionView.setCollectionViewLayout(createLayout(), animated: true)
    }
    
    private func setupSearchBar() {
        let searchController = UISearchController(searchResultsController: nil)
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        searchController.hidesNavigationBarDuringPresentation = false
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.delegate = self 
    }
    
    private func setupEnterLabel() {
        collectionView.addSubview(enterSearchTermLabel)
        enterSearchTermLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor).isActive = true
        enterSearchTermLabel.topAnchor.constraint(equalTo: collectionView.topAnchor, constant: 50).isActive = true
    }
    
    private func setupSpinner() {
        view.addSubview(spinner)
        spinner.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor).isActive = true
        spinner.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor).isActive = true
    }
    
    private func setupNavigationBar() {
        let titleLabel = UILabel()
        titleLabel.text = "PHOTOS"
        titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
        titleLabel.textColor = .black
        navigationItem.leftBarButtonItem = UIBarButtonItem.init(customView: titleLabel)
        navigationItem.rightBarButtonItems = [addBarButtonItem, actionBarButtonItem]
    }

//    // MARK: UICollectionViewDataSource
//
//    override func numberOfSections(in collectionView: UICollectionView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 1
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        enterSearchTermLabel.isHidden = photos.count != 0
//        return photos.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotosCell.reuseId, for: indexPath) as! PhotosCell
//        let unsplashedPhoto = photos[indexPath.item]
//        cell.unsplashPhoto = unsplashedPhoto
//        return cell
//    }
    
    // MARK: UICollectionViewDelegate
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateNavButtonState()
        let cell = collectionView.cellForItem(at: indexPath) as! PhotosCell
        guard let image = cell.photoImageView.image else { return }
            selectedImages.append(image)
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateNavButtonState()
        let cell = collectionView.cellForItem(at: indexPath) as! PhotosCell
        guard let image = cell.photoImageView.image else { return }
        if let index = selectedImages.firstIndex(of: image) {
            selectedImages.remove(at: index)
        }
    }
}

// MARK: - UISearchBarDelegate

extension PhotoCollectionViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print(searchText)
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { _ in
                self.networkDataFetcher.fetchImages(searchTerm: searchText) { [weak self] (searchResults) in
                guard let fetchedPhotos = searchResults else { return }
                self?.spinner.stopAnimating()
                self?.photos = fetchedPhotos.results
                self?.createSnapshot()
                self?.enterSearchTermLabel.isHidden = self?.photos.count != 0
                self?.collectionView.reloadData()
                self?.addGR()
                self?.refresh()
            }
        })
    }
}

// MARK: UICollectionViewDelegateFlowLayout

//extension PhotoCollectionViewController: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let photo = photos[indexPath.item]
//        let paddingSpace = sectionInserts.left * (itemsPerRow + 1)
//        let availableWidth = view.frame.width - paddingSpace
//        let widthPerItem = availableWidth / itemsPerRow
//        let height = CGFloat(photo.height) * widthPerItem / CGFloat(photo.width)
//        return CGSize(width: widthPerItem, height: height)
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        return sectionInserts
//    }
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
//        return sectionInserts.left
//    }
//}


//MARK: UICollectionViewLayout

extension PhotoCollectionViewController {
    
    func createLayout() -> UICollectionViewLayout {
            let layout = UICollectionViewCompositionalLayout {
                (sectionIndex: Int, layoutEnvironment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in

                
                let leadingItem = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.7),
                                                       heightDimension: .fractionalHeight(1.0)))
                leadingItem.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)

                let trailingItem = NSCollectionLayoutItem(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .fractionalHeight(0.3)))
                trailingItem.contentInsets = NSDirectionalEdgeInsets(top: 1, leading: 1, bottom: 1, trailing: 1)
                let trailingGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.3),
                                                       heightDimension: .fractionalHeight(1.0)),
                    subitem: trailingItem, count: 2)
                
                let leadingGroup = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .fractionalHeight(0.4)), subitem: trailingGroup, count: 3)

                let upperNestedGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .fractionalHeight(0.3)),
                    subitems: [leadingItem, trailingGroup])
                
                let bottomNestedGroup = NSCollectionLayoutGroup.horizontal(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .fractionalHeight(0.3)),
                    subitems: [trailingGroup, leadingItem])
                
                

                let nestedGroup = NSCollectionLayoutGroup.vertical(
                    layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                       heightDimension: .fractionalHeight(1.2)),
                    subitems: [upperNestedGroup, leadingGroup, bottomNestedGroup])
            
                
                let section = NSCollectionLayoutSection(group: nestedGroup)
                return section

            }
            return layout
        }

    private func createSnapshot() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, UnsplashPhoto>()
        snapshot.appendSections([Section.main])
        snapshot.appendItems(photos, toSection: .main)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}




