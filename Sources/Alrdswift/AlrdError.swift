//
//  File.swift
//  
//
//  Created by 冯学仕 on 2023/5/25.
//
import Foundation
//MARK: define error
public enum AlrdError:Error {
    case nullValue(_ description:String?)
    case cocoaError(_ description:String?)
    case funcationError(_ description:String?)
    
    var description:String {
        switch self {
        case .nullValue(let description):
            return "nullValue \(description ?? "")"
        case .cocoaError(let description):
            return "cocoaError \(description ?? "")"
        case .funcationError(let description):
            return "funcationError \(description ?? "")"
        }
    }
}
