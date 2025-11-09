//
//  AuthModels.swift
//  FreelanceApp
//
//  Created by Suleiman Sultanov on 25/5/25.
//

import Foundation

public struct TokenResponse: Codable {
    let accessToken: String
    let tokenType: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
    }

    func decodeJWT() -> [String: Any]? {
        let segments = accessToken.split(separator: ".")
        guard segments.count >= 2 else { return nil }

        let payloadSegment = segments[1]
        var base64 = String(payloadSegment)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64 += String(repeating: "=", count: paddingLength)
        }

        guard let payloadData = Data(base64Encoded: base64) else { return nil }
        let jsonObject = try? JSONSerialization.jsonObject(with: payloadData, options: [])
        return jsonObject as? [String: Any]
    }
}

struct ValidationError: Decodable {
    let detail: [ValidationDetail]
}

struct ValidationDetail: Decodable {
    let loc: [String]
    let msg: String
    let type: String?

    enum CodingKeys: String, CodingKey {
        case loc
        case msg
        case type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        msg = try container.decode(String.self, forKey: .msg)
        type = try container.decodeIfPresent(String.self, forKey: .type)

        if let stringArray = try? container.decode([String].self, forKey: .loc) {
            loc = stringArray
        } else {
            var unkeyed = try container.nestedUnkeyedContainer(forKey: .loc)
            var values: [String] = []
            while !unkeyed.isAtEnd {
                if let stringValue = try? unkeyed.decode(String.self) {
                    values.append(stringValue)
                } else if let intValue = try? unkeyed.decode(Int.self) {
                    values.append(String(intValue))
                } else if let doubleValue = try? unkeyed.decode(Double.self) {
                    values.append(String(doubleValue))
                } else {
                    _ = try? unkeyed.decode(EmptyDecodable.self)
                }
            }
            loc = values
        }
    }
}

private struct EmptyDecodable: Decodable {}
