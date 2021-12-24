//
//  NetworkDataFetcher.swift
//  PhotoGallery
//
//  Created by Artem Lugynets on 24.12.2021.
//

import Foundation


class NetworkDataFetcher {
    var networkService = NetworkService()
    func fetchImages(searchTerm: String, completion: @escaping (SearchResultModel?) -> ()) {
        networkService.request(searchTerm: searchTerm) { data, error in
            if let error = error {
                print("Error recieved requesting data: \(error.localizedDescription)")
                completion(nil)
            }
            let decode = self.decodeJson(type: SearchResultModel.self, from: data)
            completion(decode)
            
        }
    }
    
    func decodeJson<T: Codable>(type: T.Type, from: Data?) -> T? {
        let decoder = JSONDecoder()
        guard let data = from else {return nil}
        
        do {
            let objects = try decoder.decode(type.self, from: data)
            return objects
        } catch let jsonError {
            print(jsonError)
            return nil
        }
    }
    
}
