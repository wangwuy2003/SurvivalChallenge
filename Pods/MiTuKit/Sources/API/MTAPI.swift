//
//  MTAPI.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

public class MTAPI {
    public enum MTAPIError: Error {
        case networkError(Error)
        case dataNotFound
        case jsonParsingError(Error)
        case invalidStatusCode(Int)
        case badURL(String)
    }

    public enum Result<T> {
        case success(T)
        case failure(MTAPIError)
    }

    public static func dataRequest<T: Decodable>(with url: String, objectType: T.Type, cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, timeoutInterval: TimeInterval = 60.0, completion: @escaping (Result<T>) -> Void) {
        guard let dataURL = URL(string: url) else {
           completion(.failure(MTAPIError.badURL(url)))
           return
        }
        let session = URLSession.shared
        let request = URLRequest(url: dataURL, cachePolicy: cachePolicy, timeoutInterval: timeoutInterval)
        
        let task = session.dataTask(with: request, completionHandler: { data, response, error in
            guard error == nil else {
                completion(Result.failure(MTAPIError.networkError(error!)))
                return
            }
            
            guard let data = data else {
                completion(Result.failure(MTAPIError.dataNotFound))
                return
            }
            
            do {
                let decodedObject = try JSONDecoder().decode(objectType.self, from: data)
                completion(Result.success(decodedObject))
            } catch let error {
                completion(Result.failure(MTAPIError.jsonParsingError(error as! DecodingError)))
            }
        })
        
        task.resume()
    }
}

public extension MTAPI {
    static func getCurrentDate(timeZone: String = TimeZone.current.identifier, completion: @escaping(DateModel) -> Void) {
        let baseURL = "https://www.timeapi.io/api/Time/current/zone?timeZone="
        let url = baseURL + timeZone
        MTAPI.dataRequest(with: url, objectType: DateModel.self, completion: { result in
            switch result {
                case .success(let model):
                    completion(model)
                case .failure(let error):
                    print("\(error.localizedDescription) ->> get device date")
                    let model = DateModel(from: Date())
                    completion(model)
                }
        })
    }
}

//Date Model
public struct DateModel: Decodable {
    public let year: Int
    public let month: Int
    public let day: Int
    public let hour: Int
    public let minute: Int
    public let seconds: Int
    public let milliSeconds: Int?
    public let dateTime: String?
    public let date: String?
    public let time: String?
    public let timeZone: String?
    public let dayOfWeek: String?
    public let dstActive: Bool?
    
    ///init with date
    public init(from date: Date) {
        let calendar = Calendar.current
        
        self.year = calendar.component(.year, from: date)
        self.month = calendar.component(.month, from: date)
        self.day = calendar.component(.day, from: date)
        self.hour = calendar.component(.hour, from: date)
        self.minute = calendar.component(.minute, from: date)
        self.seconds = calendar.component(.second, from: date)
        self.milliSeconds = nil
        self.dateTime = nil
        self.date = nil
        self.time = nil
        self.timeZone = nil
        self.dayOfWeek = nil
        self.dstActive = nil
    }
    
    ///DATE FORMAT
    ///dd/MM/yyyy HH:mm:ss
    public func toDate() -> Date? {
        let string = "\(day)/\(month)/\(year) \(hour):\(minute):\(seconds)"
        let format: String = "dd/MM/yyyy HH:mm:ss"
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = format
        dateFormat.locale = Locale.current
        return dateFormat.date(from: string)
    }
    
    ///SUPPORT WITH FORMAT
    ///dd = day
    ///MM = month
    ///yyyy = year
    ///HH = hour
    ///mm = minute
    ///ss = second
    ///EXAMPLE: MM/yyyy, dd HH:mm:ss
    public func toDate(with format: String) -> Date? {
        let dayStr = format.replacingOccurrences(of: "dd", with: day < 10 ? "0\(day)" : "\(day)")
        let monthStr = dayStr.replacingOccurrences(of: "MM", with: month < 10 ? "0\(month)" : "\(month)")
        let yearStr = monthStr.replacingOccurrences(of: "yyyy", with: "\(year)")
        let hourStr = yearStr.replacingOccurrences(of: "HH", with: hour < 10 ? "0\(hour)" : "\(hour)")
        let minuteStr = hourStr.replacingOccurrences(of: "mm", with: minute < 10 ? "0\(minute)" : "\(minute)")
        let secondStr = minuteStr.replacingOccurrences(of: "ss", with: seconds < 10 ? "0\(seconds)" : "\(seconds)")
        
        let dateFormat = DateFormatter()
        dateFormat.dateFormat = format
        dateFormat.locale = Locale.current
        
        return dateFormat.date(from: secondStr)
    }
    
    private func getTime(format: String) -> Int {
        switch format {
        case "dd": return day
        case "MM": return month
        case "yyyy": return year
        case "HH": return hour
        case "mm": return minute
        case "ss": return seconds
        default: return 0
        }
    }
}

#endif
