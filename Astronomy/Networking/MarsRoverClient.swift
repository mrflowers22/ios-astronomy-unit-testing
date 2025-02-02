//
//  MarsRoverClient.swift
//  Astronomy
//
//  Created by Andrew R Madsen on 9/5/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import Foundation

class MarsRoverClient {
    //Directions states to add a constant to hold the networkDataLoader
    let networkDataLoader: NetworkDataLoader
    
    //going to create a placeHolder for the marsRover and photos so that we can test
    var marsRoverTesting: MarsRover?
    var marsPhotoReferenceTesting: [MarsPhotoReference]?
    
    //Dir - This way, MarsRoverClient will continue to function as always in existing code, but test code can provide (inject) a different networkLoader.
    init(networkDataLoader: NetworkDataLoader = URLSession.shared){
        self.networkDataLoader = networkDataLoader
    }
    
    func fetchMarsRover(named name: String,
                        using session: URLSession = URLSession.shared,
                        completion: @escaping (MarsRover?, Error?) -> Void) {
        
        let url = self.url(forInfoForRover: name)
        fetch(from: url, using: session) { (dictionary: [String : MarsRover]?, error: Error?) in

            guard let rover = dictionary?["photo_manifest"] else {
                completion(nil, error)
                return
            }
            //I added this so we can have values to test. assign our property a value so we can test to see if its nil or not
            self.marsRoverTesting = rover
            completion(rover, nil)
        }
    }
    
    func fetchPhotos(from rover: MarsRover,
                     onSol sol: Int,
                     using session: URLSession = URLSession.shared,
                     completion: @escaping ([MarsPhotoReference]?, Error?) -> Void) {
        
        let url = self.url(forPhotosfromRover: rover.name, on: sol)
        fetch(from: url, using: session) { (dictionary: [String : [MarsPhotoReference]]?, error: Error?) in
            guard let photos = dictionary?["photos"] else {
                completion(nil, error)
                return
            }
            //i added this so we can have values to test
            self.marsPhotoReferenceTesting = photos
            completion(photos, nil)
        }
    }
    
    // MARK: - Private
    //Dir: Update all MarsRoverClient methods to use the networkLoader property instead of obtaining URLSession.shared directly. If you're using the starter code ( this is ), only one method, fetch<T> needs to be changed.
    //This is because the other methods uses this method to make the network calls. see lines: 41, and 25. So it makes sense to change this because this owns the network call which we are trying to test.
    private func fetch<T: Codable>(from url: URL,
                           using session: URLSession = URLSession.shared,
                           completion: @escaping (T?, Error?) -> Void) {
//        session.dataTask(with: url) { (data, response, error) in
        networkDataLoader.loadData(from: url) { (data, error) in
            
     
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, NSError(domain: "com.LambdaSchool.Astronomy.ErrorDomain", code: -1, userInfo: nil))
                return
            }
            
            do {
                let jsonDecoder = MarsPhotoReference.jsonDecoder
                let decodedObject = try jsonDecoder.decode(T.self, from: data)
                completion(decodedObject, nil)
            } catch {
                completion(nil, error)
            }
        } //.resume() - we dont need this because our networkDataLoader has the .resume() which means we are using that to make the network call.
    }
    
    private let baseURL = URL(string: "https://api.nasa.gov/mars-photos/api/v1")!
    private let apiKey = "qzGsj0zsKk6CA9JZP1UjAbpQHabBfaPg2M5dGMB7"

    private func url(forInfoForRover roverName: String) -> URL {
        var url = baseURL
        url.appendPathComponent("manifests")
        url.appendPathComponent(roverName)
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        return urlComponents.url!
    }
    
    private func url(forPhotosfromRover roverName: String, on sol: Int) -> URL {
        var url = baseURL
        url.appendPathComponent("rovers")
        url.appendPathComponent(roverName)
        url.appendPathComponent("photos")
        let urlComponents = NSURLComponents(url: url, resolvingAgainstBaseURL: true)!
        urlComponents.queryItems = [URLQueryItem(name: "sol", value: String(sol)),
                                    URLQueryItem(name: "api_key", value: apiKey)]
        return urlComponents.url!
    }
}
