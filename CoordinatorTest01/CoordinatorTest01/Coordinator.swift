//
//  Coordinator.swift
//  CoordinatorTest01
//
//  Created by Ting Chen on 3/6/20.
//  Copyright © 2020 Ting Chen. All rights reserved.
//

import UIKit

protocol Coordinator {
    var childCoordinators: [Coordinator] { get set }
    var navigationController: UINavigationController { get set }

    func start()
}
