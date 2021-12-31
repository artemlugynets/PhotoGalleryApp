//
//  NetworkService.swift
//  PhotoGallery
//
//  Created by Artem Lugynets on 24.12.2021.
//

import Foundation

class NetworkService {
    
    // URLSession
    
    func request(searchTerm: String, completion: @escaping (Data?, Error?) -> Void) {
        let parametres = self.prepareParametres(searchTerm: searchTerm)
        let url = self.url(params: parametres)
        var request = URLRequest(url: url)
        request.allHTTPHeaderFields = prepareHeader()
        request.httpMethod = "GET"
        let task = createDataTask(from: request, completion: completion)
        task.resume()
    }
    
    private func prepareHeader() -> [String:String] {
        var headers = [String:String]()
        headers["Authorization"] = "Client-ID u-QHPf0G4q28exDWavfQwn41nZA_iyk0vLFL8IYAais"
        return headers
    }
    
    private func prepareParametres(searchTerm: String?) -> [String:String] {
        var parametres = [String:String]()
        parametres["query"] = searchTerm
        parametres["page"] = String(1)
        parametres["per_page"] = String(33)
        return parametres
    }
    
    private func url(params: [String:String]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.unsplash.com"
        components.path = "/search/photos"
        components.queryItems = params.map { URLQueryItem(name: $0, value: $1)}
        return components.url!
    }
    
    private func createDataTask(from request: URLRequest, completion: @escaping (Data?, Error?) -> Void) -> URLSessionDataTask {
        return URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
    }
}
