import CoreData

protocol CoreDataManagerType {
  var viewContext: NSManagedObjectContext { get }
  func save() throws
  func performBackgroundTask(_ block: @escaping (NSManagedObjectContext) -> Void)
  func newBackgroundContext() -> NSManagedObjectContext
}
