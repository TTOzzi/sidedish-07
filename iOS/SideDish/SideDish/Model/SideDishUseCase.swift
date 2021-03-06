//
//  SideDishUseCase.swift
//  SideDish
//
//  Created by TTOzzi on 2020/04/25.
//  Copyright © 2020 TTOzzi. All rights reserved.
//

import Foundation

struct SideDishUseCase {
    enum Category: String {
        case main, soup, side
        
        var section: Int {
            switch self {
            case .main:
                return 0
            case .soup:
                return 1
            case .side:
                return 2
            }
        }
    }
    
    static let loadFailed = NSNotification.Name.init("loadFailed")
    static let serverUrl = "http://15.165.65.200/products/"
    static var token: String?
    
    static func loadAll(completed: @escaping (Int, [SideDish]) -> ()) {
        loadList(category: .main, completed: completed)
        loadList(category: .soup, completed: completed)
        loadList(category: .side, completed: completed)
    }
    
    static func loadList(category: Category, completed: @escaping (Int, [SideDish]) -> ()) {
        NetworkManager.httpRequest(url: serverUrl + category.rawValue, method: .GET, completionHandler: { (data, _, error) in
            guard let data = data else {
                NotificationCenter.default.post(name: loadFailed, object: nil, userInfo: ["title":"데이터 로드 실패!","message":"네트워크 연결을 확인해주세요!"])
                return
            }
            let list = try? JSONDecoder().decode(SideDishData.self, from: data).content
            completed(category.section, list ?? [])
        })
    }
    
    static func loadDetail(hash: String, completed: @escaping (DetailSideDish) -> ()) {
        NetworkManager.httpRequest(url: serverUrl + "detail/\(hash)", method: .GET) { (data, response, error) in
            guard let data = data else {
                NotificationCenter.default.post(name: loadFailed, object: nil, userInfo: ["title":"데이터 로드 실패!","message":"네트워크 연결을 확인해주세요!"])
                return
            }
            guard let detail = try? JSONDecoder().decode(DetailSideDishData.self, from: data).content else { return }
            
            completed(detail)
        }
    }
    
    static func loadImage(url: String, completed: @escaping (Data) -> ()) {
        NetworkManager.httpRequest(url: url, method: .GET) { (data, response, error) in
            guard let data = data else {
                NotificationCenter.default.post(name: loadFailed, object: nil, userInfo: ["title":"이미지 로드 실패!","message":"네트워크 연결을 확인해주세요!"])
                return
            }
            completed(data)
        }
    }
    
    static func orderRequest(hash: String, completed: @escaping (OrderResponse) -> ()) {
        NetworkManager.httpRequestWith(token: token, url: serverUrl + "detail/\(hash)/order") { (data, response, error) in
            guard let data = data else {
                NotificationCenter.default.post(name: loadFailed, object: nil, userInfo: ["title":"데이터 로드 실패!","message":"네트워크 연결을 확인해주세요!"])
                return
            }
            guard let orderResponse = try? JSONDecoder().decode(OrderResponse.self, from: data) else { return }
            completed(orderResponse)
        }
    }
}

