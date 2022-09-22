import Foundation
import CoreData
import SoraKeystore

protocol StorageMigrating {
    func requiresMigration() -> Bool
    func migrate(_ completion: @escaping () -> Void)
}

enum UserStorageMigratorKeys {
    static let keystoreMigrator = "keystoreMigrator"
    static let settingsMigrator = "settingsMigrator"
}

final class UserStorageMigrator {
    let storeURL: URL
    let modelDirectory: String
    let keystore: KeystoreProtocol
    let settings: SettingsManagerProtocol
    let fileManager: FileManager
    let targetVersion: UserStorageVersion

    init(
        targetVersion: UserStorageVersion,
        storeURL: URL,
        modelDirectory: String,
        keystore: KeystoreProtocol,
        settings: SettingsManagerProtocol,
        fileManager: FileManager
    ) {
        self.targetVersion = targetVersion
        self.storeURL = storeURL
        self.modelDirectory = modelDirectory
        self.keystore = keystore
        self.settings = settings
        self.fileManager = fileManager
    }

    func performMigration() {
        forceWALCheckpointingForStore(at: storeURL)

        let maybeMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        )

        guard
            let metadata = maybeMetadata,
            let sourceVersion = compatibleVersionForStoreMetadata(metadata) else {
            fatalError("Unknown store version at URL \(storeURL)")
        }

        do {
            let migrationDirName = UUID().uuidString
            let tmpMigrationDirURL = URL(
                fileURLWithPath: NSTemporaryDirectory(),
                isDirectory: true
            ).appendingPathComponent(migrationDirName)

            try fileManager.createDirectory(at: tmpMigrationDirURL, withIntermediateDirectories: true)

            try performMigration(
                from: sourceVersion,
                to: targetVersion,
                storeURL: storeURL,
                tmpMigrationDirURL: tmpMigrationDirURL
            )

            try fileManager.removeItem(at: tmpMigrationDirURL)
        } catch {
            fatalError("Migration failed with error \(error)")
        }
    }

    private func performMigration(
        from sourceVersion: UserStorageVersion,
        to destinationVersion: UserStorageVersion,
        storeURL: URL,
        tmpMigrationDirURL: URL
    ) throws {
        var currentVersion = sourceVersion
        var currentURL = storeURL

        let keystoreMigrator = KeystoreMigrator(
            sourceVersion: sourceVersion,
            destinationVersion: destinationVersion,
            keystore: keystore
        )

        let settingsMigrator = SettingsMigrator(
            sourceVersion: sourceVersion,
            destinationVersion: destinationVersion,
            settings: settings
        )

        while currentVersion != destinationVersion, let nextVersion = currentVersion.nextVersion() {
            let currentModel = createManagedObjectModel(forResource: currentVersion.rawValue)
            let nextModel = createManagedObjectModel(forResource: nextVersion.rawValue)

            try keystoreMigrator.switchVersion()
            try settingsMigrator.switchVersion()

            let mapping = try createMapping(from: currentModel, nextModel: nextModel)

            let manager = NSMigrationManager(sourceModel: currentModel, destinationModel: nextModel)

            var userInfo = manager.userInfo ?? [AnyHashable: Any]()
            userInfo[UserStorageMigratorKeys.keystoreMigrator] = keystoreMigrator
            userInfo[UserStorageMigratorKeys.settingsMigrator] = settingsMigrator
            manager.userInfo = userInfo

            let nextStepURL = tmpMigrationDirURL.appendingPathComponent(UUID().uuidString)

            try manager.migrateStore(
                from: currentURL,
                sourceType: NSSQLiteStoreType,
                options: nil,
                with: mapping,
                toDestinationURL: nextStepURL,
                destinationType: NSSQLiteStoreType,
                destinationOptions: nil
            )

            if currentURL != storeURL {
                try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
            }

            currentVersion = nextVersion
            currentURL = nextStepURL
        }

        try keystoreMigrator.finalize()
        try settingsMigrator.finalize()

        try NSPersistentStoreCoordinator.replaceStore(at: storeURL, withStoreAt: currentURL)

        if currentURL != storeURL {
            try NSPersistentStoreCoordinator.destroyStore(at: currentURL)
        }
    }

    private func checkIfMigrationNeeded(to version: UserStorageVersion) -> Bool {
        let storageExists = fileManager.fileExists(atPath: storeURL.path)

        guard storageExists else {
            return false
        }

        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            return false
        }

        let compatibleVersion = compatibleVersionForStoreMetadata(metadata)

        return compatibleVersion != version
    }

    private func compatibleVersionForStoreMetadata(_ metadata: [String: Any]) -> UserStorageVersion? {
        let compatibleVersion = UserStorageVersion.allCases.first {
            let model = createManagedObjectModel(forResource: $0.rawValue)
            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }

        return compatibleVersion
    }

    private func createManagedObjectModel(forResource resource: String) -> NSManagedObjectModel {
        let bundle = Bundle.main
        let omoURL = bundle.url(
            forResource: resource,
            withExtension: "omo",
            subdirectory: modelDirectory
        )

        let momURL = bundle.url(
            forResource: resource,
            withExtension: "mom",
            subdirectory: modelDirectory
        )

        guard
            let modelURL = omoURL ?? momURL,
            let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to load model in bundle for resource \(resource)")
        }

        return model
    }

    private func createMapping(
        from sourceModel: NSManagedObjectModel,
        nextModel: NSManagedObjectModel
    ) throws -> NSMappingModel {
        let maybeCustomMapping = NSMappingModel(
            from: [Bundle.main],
            forSourceModel: sourceModel,
            destinationModel: nextModel
        )

        if let customMapping = maybeCustomMapping {
            return customMapping
        }

        return try NSMappingModel.inferredMappingModel(
            forSourceModel: sourceModel,
            destinationModel: nextModel
        )
    }

    private func forceWALCheckpointingForStore(at storeURL: URL) {
        let maybeMetadata = try? NSPersistentStoreCoordinator.metadataForPersistentStore(
            ofType: NSSQLiteStoreType,
            at: storeURL,
            options: nil
        )

        guard
            let metadata = maybeMetadata,
            let currentModel = NSManagedObjectModel.mergedModel(
                from: [Bundle.main],
                forStoreMetadata: metadata
            ) else {
            return
        }

        do {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: currentModel)

            let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
            let store = try persistentStoreCoordinator.addPersistentStore(at: storeURL, options: options)
            try persistentStoreCoordinator.remove(store)
        } catch {
            fatalError("Failed to force WAL checkpointing, error: \(error)")
        }
    }
}

extension UserStorageMigrator: StorageMigrating {
    func requiresMigration() -> Bool {
        checkIfMigrationNeeded(to: targetVersion)
    }

    func migrate(_ completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performMigration()

            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

final class SubstrateStorageMigrator {
    let modelDirectory: String
    let model: SubstrateStorageVersion
    let storeURL: URL
    let fileManager: FileManager

    init(
        storeURL: URL,
        modelDirectory: String,
        model: SubstrateStorageVersion,
        fileManager: FileManager
    ) {
        self.storeURL = storeURL
        self.model = model
        self.modelDirectory = modelDirectory
        self.fileManager = fileManager
    }
}

extension SubstrateStorageMigrator: Migrating {
    func migrate() throws {
        guard requiresMigration() else {
            return
        }
        migrate {
            Logger.shared.info("Substrate storage migration was completed")
        }
    }
}

extension SubstrateStorageMigrator: StorageMigrating {
    func requiresMigration() -> Bool {
        checkIfMigrationNeeded(
            to: SubstrateStorageVersion.current,
            storeURL: storeURL,
            fileManager: fileManager,
            modelDirectory: modelDirectory
        )
    }

    private func performMigration() {
        let destinationVersion = SubstrateStorageVersion.current

        let mom = createManagedObjectModel(
            forResource: destinationVersion.rawValue,
            modelDirectory: modelDirectory
        )

        let psc = NSPersistentStoreCoordinator(managedObjectModel: mom)
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true
        ]
        do {
            try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options)
        } catch {
            fatalError("Failed to add persistent store: \(error)")
        }
    }

    func migrate(_ completion: @escaping () -> Void) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.performMigration()

            DispatchQueue.main.async {
                completion()
            }
        }
    }
}

enum SubstrateStorageVersion: String, CaseIterable {
    case version1 = "SubstrateDataModel"
    case version2 = "SubstrateDataModel2"

    static var current: SubstrateStorageVersion {
        allCases.last!
    }

    var nextVersion: SubstrateStorageVersion? {
        switch self {
        case .version1:
            return .version2
        case .version2:
            return nil
        }
    }
}

private extension StorageMigrating {
    typealias Version = CaseIterable & RawRepresentable & Equatable

    func checkIfMigrationNeeded<T>(
        to version: T,
        storeURL: URL,
        fileManager: FileManager,
        modelDirectory: String
    ) -> Bool where T: Version, T.RawValue == String {
        let storageExists = fileManager.fileExists(atPath: storeURL.path)

        guard storageExists else {
            return false
        }

        guard let metadata = NSPersistentStoreCoordinator.metadata(at: storeURL) else {
            return false
        }

        let compatibleVersion = T.allCases.first {
            let model = createManagedObjectModel(forResource: $0.rawValue, modelDirectory: modelDirectory)
            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }

        return compatibleVersion != version
    }

    func compatibleVersionForStoreMetadata<T>(
        _ metadata: [String: Any],
        modelDirectory: String
    ) -> T? where T: Version, T.RawValue == String {
        let compatibleVersion = T.allCases.first {
            let model = createManagedObjectModel(forResource: $0.rawValue, modelDirectory: modelDirectory)
            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        }

        return compatibleVersion
    }

    func createManagedObjectModel(forResource resource: String, modelDirectory: String) -> NSManagedObjectModel {
        let bundle = Bundle.main
        let omoURL = bundle.url(
            forResource: resource,
            withExtension: "omo",
            subdirectory: modelDirectory
        )

        let momURL = bundle.url(
            forResource: resource,
            withExtension: "mom",
            subdirectory: modelDirectory
        )

        guard
            let modelURL = omoURL ?? momURL,
            let model = NSManagedObjectModel(contentsOf: modelURL) else {
            fatalError("Unable to load model in bundle for resource \(resource)")
        }

        return model
    }
}
