import UIKit

/**
 Contexto:
 
 El equipo de backend ha liberado una nueva versión de su API, por lo que algunos modelos de respuesta de datos han cambiado.
 
 Por ejemplo, en la estructura `Cat` te han pedido cambiar lo siguiente:
 - El `id` cambió de nombre a `identifier` y ahora es de tipo `String`.
 - La propiedad `size` ahora es un objeto `Size` con nuevas propiedades (ver línea #46 `Size`).
 
 Hasta ahora todo funcionaba muy bien y habías aplicado casi todos los principios de SOLID pero al modificar las estructuras de la capa de red has afectado la vista `CatsViewController`.
 
 Esto no es un comportamiento esperado, parece que tus vistas dependen de los detalles de implementación del backend y no de abstracciones.
 
 Instrucciones:
 
 - 1. Aplica los cambios del backend:
    - Reemplaza el nombre del archivo `cats` por `cats-v2` en la línea #115, para simular los cambios del backend.
    - Corre el playground y valida que la decodificación ha fallado.
    - Modifica la estructura `Cat` para cumplir con los cambios del backend.
    - Corre el playground y mira las cosas que se rompen en `CatsViewController`.
 
 - 2. Crea abstracciones para tu vista:
    - Crea un modelo `CatViewData` que represente los datos que tu vista necesita. Guíate con los errores de compilación para identificar estos datos.
    - Crea un protocolo  `CatsService` específico para tu vista, que emita objetos concretos de tipo `CatViewData` en un closure. Reemplaza el `Fetcher` con este servicio en el constructor de `CatsViewController`.
    - Crea una implementación de `CatsService` llamada `CatsServiceImp` que reciba un `Fetcher` en el constructor.
    - Arregla los errores de compilación de la clase `CatsRouter` usando las nuevas implementaciones, inyectándolas donde corresponda.
 
 - 3. Arregla las llamadas a `Saver`:
    - Inyecta una instancia de `Saver` a `CatsService`
    - Agréga un closure `didSelect: () -> Void` al modelo `CatViewData`
    - Impleméntalo en el `CatsServiceImp` y dentro llama la función `saveData` del `Saver` que acabas de inyectar.
    - Elimina el `Saver` de `CatsViewController` y reemplaza las llamadas por el closure del `CatViewData`.
    - Arregla los errores de compilación de la clase `CatsRouter` usando las nuevas implementaciones, inyectándolas donde corresponda.
 
 NOTA: `CatViewData` NO debe ser `Decodable` ni `Encodable` ya que estos protocolos también son detalles de implementación específicos del backend.
*/

// MARK: - Backend models to modify

struct Cat: Codable {
    let id: Int
    let breed: String
    let size: String
}

struct Size {
    let heightInCentimeters: Double
    let weightInKilograms: Double
    let description: String
}

// MARK: - CatsViewController

final class CatsViewController {
    
    private let fetcher: Fetcher
    private let saver: Saver
    private var cats: [Cat] = []
    
    init(fetcher: Fetcher, saver: Saver) {
        self.fetcher = fetcher
        self.saver = saver
        
        callFetcher()
    }
    
    private func callFetcher() {
        fetcher.fetchData() { [weak self] (result: Result<[Cat], Error>) in
            switch result {
            case let .success(cats):
                self?.iShouldBeCalledToLoadCats(cats)
            case let .failure(error):
                self?.iShouldBeCalledWhenAnErrorOccurs(error)
            }
        }
    }
    
    private func iShouldBeCalledWhenAnErrorOccurs(_ error: Error) {
        print(error.localizedDescription)
    }
    
    private func iShouldBeCalledToLoadCats(_ cats: [Cat]) {
        self.cats = cats
        for cat in cats {
            print("Label - Cat Breed:", cat.breed)
            print("Label - Cat Size:", cat.size)
        }
    }
    
    func addFavoriteCat(at index: Int) {
        guard cats.count > index else { return }
        saveFavorite(cats[index])
    }
    
    private func saveFavorite(_ cat: Cat) {
        saver.saveData(data: cat, key: "favorite-cats-\(cat.id)") { result in
            switch result {
            case let .success(cat):
                print("Saved cat with id:", cat.id)
            case let .failure(error):
                print("Oops! An \(error) occured while saving:", cat)
            }
        }
    }
}

// MARK: - CatsRouter

final class CatsRouter {

    private let catsViewController: CatsViewController
    
    init() {
        let decodableResultsAdapter = JSONDecoderResultAdapter(decoder: JSONDecoder())
        let catsFetcher = LocalFileFetcher(fileName: "cats", fileExtension: "json", decodableResultAdapter: decodableResultsAdapter)
        let favoriteCatsSaver = UserDefaultsSaver()
        catsViewController = CatsViewController(fetcher: catsFetcher, saver: favoriteCatsSaver)
    }
    
    func simulateUserSelectingCats() {
        print("MARK: - Start simulated cat selection")
        for index in 0...9 {
            catsViewController.addFavoriteCat(at: index)
        }
    }
}

let catsRouter = CatsRouter()
catsRouter.simulateUserSelectingCats()
