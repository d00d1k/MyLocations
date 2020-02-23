//
//  SceneDelegate.swift
//  MyLocations
//
//  Created by Nikita Kalyuzhniy on 2/19/20.
//  Copyright © 2020 Nikita Kalyuzhniy. All rights reserved.
//

import UIKit
import CoreData

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    lazy var managedObjectContext: NSManagedObjectContext = self.persistenConteiner.viewContext
    
    lazy var persistenConteiner: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "DataModel")
        container.loadPersistentStores(completionHandler: {
            storeDescription, error in
            if let error = error {
                fatalError("Could load data store: \(error)")
            }
        })
        return container
    }()
    
    func listenForFatalCoreDataNotifications() {
        
        NotificationCenter.default.addObserver(forName: MyManagedObjectContextSaveDidFailNotification,
                                               object: nil,
                                               queue: OperationQueue.main,
                                               using: {
                                                
                                                notification in
                                                
                                                let alert = UIAlertController(
                                                    title: "Internal Error",
                                                    message: "There was a fatal error in the app and it cannot continue.\n\n" + "Press OK to terminate the app. Sorry for the inconvenience.",
                                                    preferredStyle: .alert)
                                                
                                                let action = UIAlertAction(title: "OK",
                                                                           style: .default) { _ in
                                                                            let exception = NSException(
                                                                                name: NSExceptionName.internalInconsistencyException,
                                                                                reason: "Fatal Core Data error",
                                                                                userInfo: nil)
                                                                            exception.raise()
                                                }
                                                alert.addAction(action)
                                                
                                                self.viewControllerForShowingAlert().present(alert, animated: true, completion: nil)
                                                
        })
    }
    
    func viewControllerForShowingAlert() -> UIViewController {
        
        let rootViewController = self.window!.rootViewController!
        
        if let presentedViewController =
            rootViewController.presentedViewController {
            return presentedViewController
        } else {
            return rootViewController
        }
    }
    
    
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        
        let tabBarController = window!.rootViewController as! UITabBarController
        if let tabBarViewControllers = tabBarController.viewControllers {
            let currentLocationViewController = tabBarViewControllers[0] as! CurrentLocationViewController
            currentLocationViewController.managedObjectContext = managedObjectContext
            
            print("Document directory -> \(applicationDocumentDirectory)")
        }

        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        listenForFatalCoreDataNotifications()
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        listenForFatalCoreDataNotifications()
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        listenForFatalCoreDataNotifications()
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        listenForFatalCoreDataNotifications()
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        listenForFatalCoreDataNotifications()
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.

        // Save changes in the application's managed object context when the application transitions to the background.
        (UIApplication.shared.delegate as? AppDelegate)?.saveContext()
    }


}

