import CoreData

final class CoreDataManager: CoreDataManagerType {
  private let persistentContainer: NSPersistentContainer

  var viewContext: NSManagedObjectContext {
    persistentContainer.viewContext
  }

  init(modelName: String = "RecapDataModel", inMemory: Bool = false) {
    persistentContainer = NSPersistentContainer(name: modelName)

    if inMemory {
      persistentContainer.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
    }

    persistentContainer.loadPersistentStores { _, error in
      if let error = error {
        fatalError("Failed to load Core Data stack: \(error)")
      }
    }

    viewContext.automaticallyMergesChangesFromParent = true
  }

  func save() throws {
    guard viewContext.hasChanges else { return }
    try viewContext.save()
  }

  func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void) {
    persistentContainer.performBackgroundTask(block)
  }

  func newBackgroundContext() -> NSManagedObjectContext {
    persistentContainer.newBackgroundContext()
  }
}
