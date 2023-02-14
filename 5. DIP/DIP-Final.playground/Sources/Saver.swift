import Foundation

public protocol Saver {
    func saveData<T: Encodable>(data: T, key: String, completion: @escaping (Result<T, Error>) -> Void)
}
