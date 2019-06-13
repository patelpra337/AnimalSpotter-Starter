//
//  APIController.swift
//  AnimalSpotter
//
//  Created by Ben Gohlke on 4/16/19.
//  Copyright © 2019 Lambda School. All rights reserved.
//

import Foundation
import UIKit

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
}
// Create enum for NetworkError to make things easier for error handling
enum NetworkError: Error {
    case noAuth
    case badAuth
    case otherError
    case badData
    case noDecode
}

class APIController {
    
    private let baseUrl = URL(string: "https://lambdaanimalspotter.vapor.cloud/api")!
    //
    var bearer: Bearer?
    // 1.  create function for sign up
    func signUp(with user: User, completion: @escaping (Error?) -> ()) {
        // 2.  Create Endpoint URL
        let signUpURL = self.baseUrl.appendingPathComponent("users/signup")
        // 3.  Setup Request
        var request = URLRequest(url: signUpURL)
        request.httpMethod = HTTPMethod.post.rawValue
        // 4.  Setup a setValue of which is Content-Type standard
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 5. Initialize JSON Encoder
        let jsonEncoder = JSONEncoder()
        // Encode the data, catch errors
        
        do {
            let jsonData = try jsonEncoder.encode(user)
            request.httpBody = jsonData
        } catch {
            NSLog("Error encoding user object: \(error)")
            completion(error)
            return
        }
        
        // Create Data Task, Handle Bad Response and Errors
        URLSession.shared.dataTask(with: request) { (_, response, error) in
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(NSError(domain: "", code: response.statusCode, userInfo: nil))
                return
            }
            
            if let error = error {
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    
    // create function for sign in
    func signIn(with user: User, completion: @escaping (Error?) -> ()) {
        let loginURL = baseUrl.appendingPathComponent("users/login")
        
        var request = URLRequest(url: loginURL)
        request.httpMethod = HTTPMethod.post.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let jsonEncoder = JSONEncoder()
        
        do {
            let jsonData = try jsonEncoder.encode(user)
            request.httpBody = jsonData
        } catch {
            NSLog("Error encoding user object: \(error)")
            completion(error)
            return
        }
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse,
                response.statusCode != 200 {
                completion(NSError(domain: "", code: response.statusCode, userInfo: nil))
                return
            }
            if let error = error {
                completion(error)
                return
            }
    
            guard let data = data else {
                completion(NSError())
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                self.bearer = try decoder.decode(Bearer.self, from: data)
            } catch {
                NSLog("Error encoding user object: \(error)")
                completion(error)
                return
            }
            
            completion(nil)
        }.resume()
    }
    // create function for fetching all animal names
    func fetchAllAnimalNames(completion: @escaping (Result<[String], NetworkError>) -> Void) {
        guard let bearer = self.bearer else {
            completion(.failure(.noAuth))
            return
        }
        
        let allAnimalURL = self.baseUrl.appendingPathComponent("animals/all")
        
        var request = URLRequest(url: allAnimalURL)
        request.httpMethod = HTTPMethod.get.rawValue
        request.addValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse,
                response.statusCode == 401 {
                completion(.failure(.badAuth))
                return
            }
            
            if let _ = error {
                completion(.failure(.badData))
                return
            }
            
            let decoder = JSONDecoder()
            
            do {
                let animalNames = try decoder.decode([String].self, from: data)
                completion(.success(animalNames))
            } catch {
                NSLog("Error decoding animal objects: \(error)")
                completion(.failure(.noDecode))
                return
            }
        }.resume()
    }
    // create a function for fetching individual animal
    
    func fetchDetailsForAnimal(for animalName: String, completion: @escaping (Result<Animal, NetworkError>) -> Void) {
        guard let bearer = self.bearer else {
            completion(.failure(.noAuth))
            return
        }
        
        let AnimalURL = self.baseUrl.appendingPathComponent("animals/\(animalName)")
        
        var request = URLRequest(url: AnimalURL)
        request.httpMethod = HTTPMethod.get.rawValue
        request.addValue("Bearer \(bearer.token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse,
                response.statusCode == 401 {
                completion(.failure(.noAuth))
                return
            }
            
            if let _ = error {
                completion(.failure(.badData))
                return
            }
            
            guard let data = data else {
                completion(.failure(.badData))
                return
            }
            
            let decoder = JSONDecoder()
            decoder.dataDecodingStrategy = .secondsSince1970
            
            do {
                let animalNames = try decoder.decode([Animal].self, from: data)
                completion(.success(animal))
            } catch {
                NSLog("Error decoding animal objects: \(error)")
                completion(.failure(.noDecode))
                return
            }
            }.resume()
    }
    // create function to fetch image
    
    func fetchImage(at urlString: String, completion: @escaping (Result<UIImage, NetworkError>) -> Void) {
        let imageUrl = URL(string: urlString)!
    
        URLSession.shared.dataTask(with: imageUrl) { (data, _, error ) in
            if let _ = error {
                completion(.failure(.otherError))
                return
        }
    
        guard let data = data else {
        completion(.failure(.badData))
        return
        }
    
        let image = UIImage(data: data)!
        completion(.success(image))
        }.resume()
    }
}

