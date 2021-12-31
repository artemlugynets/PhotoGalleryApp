//
//  SearchResults.swift
//  PhotoGallery
//
//  Created by Artem Lugynets on 24.12.2021.
//

import Foundation

struct SearchResultModel: Codable {
    let total: Int
    let results: [UnsplashPhoto]
}

struct UnsplashPhoto: Codable, Hashable {
    let width: Int
    let height: Int
    let urls: [UrlKind.RawValue:String]
}

enum UrlKind: String {
    case raw
    case full
    case regular
    case small
    case thumb
}
