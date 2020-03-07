//
//  MainCoordinator.swift
//  CoordinatorTest01
//
//  Created by Ting Chen on 3/6/20.
//  Copyright © 2020 Ting Chen. All rights reserved.
//

import UIKit

class MainCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        let vc = EntryVC.instantiate()
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: false)
    }
    
    func goFirst() {
        let vc = FirstVC.instantiate()
        vc.coordinator = self
        navigationController.navigationBar.tintColor = .systemTeal
        navigationController.pushViewController(vc, animated: true)
    }

    func goSecond() {
        let vc = SecondVC.instantiate()
        vc.coordinator = self
        navigationController.navigationBar.tintColor = .systemYellow
        navigationController.pushViewController(vc, animated: true)
    }
}
