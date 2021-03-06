//
//  AddressProvider.swift
//  MeMailer5000
//
//  Created by Alex Brashear on 1/31/17.
//  Copyright © 2017 memailer. All rights reserved.
//

import Foundation

typealias AddressVerificationCompletion = (_ address: Address?, _ error: AddressError?) -> Void

class AddressProvider {
    private let parser = AddressParser()
    private let verifyURLString = "https://api.lob.com/v1/us_verifications"
    private let networkClient = NetworkClient()
    
    func verify(address: Address, completion: @escaping AddressVerificationCompletion) {
        verify(name: address.name, line1: address.primaryLine, line2: address.secondaryLine, city: address.city, state: address.state, zip: address.zip, completion: completion)
    }
    
    func verify(name: String, line1: String, line2: String, city: String, state: String, zip: String, completion: @escaping AddressVerificationCompletion) {
        guard let url = URL(string: verifyURLString) else { return completion(nil, .unknownFailure) }
        let data = formatHTTPBody(withLine1: line1, line2: line2, city: city, state: state, zip: zip)
        networkClient.POST(url: url, data: data) { [weak self] json in
            guard let json = json else { return completion(nil, .unknownFailure) }
            let (address, error) = self?.parser.parse(json: json, name: name) ?? (nil, .unknownFailure)
            DispatchQueue.main.async {
                completion(address, error)
            }
        }
    }
    
    private func formatHTTPBody(withLine1 line1: String, line2: String, city: String, state: String, zip: String) -> Data? {
        return "primary_line=\(line1)&secondary_line=\(line2)&city=\(city)&state=\(state)&zip_code=\(zip)".data(using: .utf8)
    }
}
