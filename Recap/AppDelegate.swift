//
//  AppDelegate.swift
//  MeMailer5000
//
//  Created by Alex Brashear on 1/28/17.
//  Copyright © 2017 memailer. All rights reserved.
//

import UIKit
import AWSS3
import Apollo
import FacebookCore
import FacebookLogin
import Iconic
import Braintree

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private let persistanceManager = PersistanceManager()
    
    private var rootFlowCoordinator: RootFlowCoordinator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        BTAppSwitch.setReturnURLScheme("\(Bundle.main.bundleIdentifier!).payments")
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        FontAwesomeIcon.register()
        setupAWS()

        let token = persistanceManager.token
        let userController = UserController(graphql: ApolloWrapper(token: token), persistanceManager: persistanceManager)
        if token != nil {
            userController.loadUser()
        }
        
        let paymentsController = PaymentsController(userController: userController)
        let photoSender = PhotoSender(userController: userController)
        let photoManager = PhotoManager(imageUploader: ImageUploader(), userController: userController, photoSender: photoSender)
        
        rootFlowCoordinator = RootFlowCoordinator(userController: userController, paymentsController: paymentsController, photoManager: photoManager)
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .white
        window?.rootViewController = rootFlowCoordinator?.rootViewController
        rootFlowCoordinator?.load()
        window?.makeKeyAndVisible()
        return true
    }

    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if url.scheme?.localizedCaseInsensitiveCompare("\(Bundle.main.bundleIdentifier!).payments") == .orderedSame {
            return BTAppSwitch.handleOpen(url, options: options)
        } else {
            return SDKApplicationDelegate.shared.application(app, open: url, options: options)
        }
    }
}

extension AppDelegate {
    func setupAWS() {
        let credentialProvider = AWSCognitoCredentialsProvider(regionType: .USEast1, identityPoolId: AWSCredentials.identityPoolId)
        let configuration = AWSServiceConfiguration(region:.USEast1, credentialsProvider: credentialProvider)
        AWSServiceManager.default().defaultServiceConfiguration = configuration
    }
}
