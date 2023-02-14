import Foundation

public struct DataNotFoundError: Error {
    public init() { }
}

extension DataNotFoundError: LocalizedError {
    public var errorDescription: String? {
        "Ha ocurrido un error al obtener los datos."
    }
}
