//
//  PCCoordinator.swift
//
//  Created by Su PingChen on 2018/10/13.
//  Copyright © 2018 SPC. All rights reserved.
//

import Foundation
import UIKit
import GameKit


class CoordinatorStateMachine: GKStateMachine {
    weak var coordinatorViewController: UIViewController?
    
    init(viewController: UIViewController, states: [CoordinatorState]) {
        coordinatorViewController = viewController
        super.init(states: states)
    }
}

class CoordinatorState: GKState {
    
    private var viewControllerClass: UIViewController.Type
    
    private var coordinatorStateMachine: CoordinatorStateMachine? {
        return super.stateMachine as? CoordinatorStateMachine
    }
    
    init(viewControllerClass: UIViewController.Type) {
        self.viewControllerClass = viewControllerClass
        super.init()
    }
    
    override func didEnter(from previousState: GKState?) {
        guard let stateMachine = stateMachine as? CoordinatorStateMachine else { return }
        guard let parent = stateMachine.coordinatorViewController else { return }
        guard let _ /*previousState*/ = previousState else {
            // This is the first state, so we need to initialize this view controller first.
            let viewController = viewControllerClass.init()
            viewController.view.frame = parent.view.bounds
            
            viewController.willMove(toParent: parent)
            parent.view.addSubview(viewController.view)
            viewController.didMove(toParent: parent)
            return
        }
    }
    
    override func willExit(to nextState: GKState) {
        guard let stateMachine = coordinatorStateMachine else { return }
        guard let nextState = nextState as? CoordinatorState else {
            assertionFailure("New state does not conform to designed class.")
            return
        }
        let nextViewController = nextState.viewControllerClass.init()
        let children = stateMachine.coordinatorViewController?.children
        if let currentViewController = children?.first(where: {type(of: $0) == viewControllerClass}) {
            present(from: currentViewController, to: nextViewController)
        } else {
            assertionFailure("Couldn't find corresponding view controller.")
        }
    }
    
    /// Override this method to define valid next state.
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        return true
    }
    
    /// Override this method to provide different animation block
    @objc func animationBlock(from: UIViewController, to: UIViewController) -> (() -> Void)? {
        to.view.alpha = 0
        return {
            from.view.alpha = 0
            to.view.alpha = 1
        }
    }
    
    /// Override this method to provide different animation option
    @objc func animationOption(from: UIViewController, to: UIViewController) -> UIView.AnimationOptions {
        return .beginFromCurrentState
    }

}

extension CoordinatorState {
    
    private func present(from: UIViewController, to: UIViewController) {
        guard let stateMachine = coordinatorStateMachine else { return }
        guard let parent = stateMachine.coordinatorViewController else { return }
        
        from.willMove(toParent: nil)
        parent.addChild(to)
        to.view.frame = from.view.frame
        
        if let animationBlock = self.animationBlock(from: from, to: to) {
            let animationOption = self.animationOption(from: from, to: to)
            parent.transition(from: from, to: to, duration: 0.3, options: animationOption, animations: animationBlock) { finished in
                from.removeFromParent()
                to.didMove(toParent: parent)
            }
        } else {
            let superview = from.view.superview
            from.view.removeFromSuperview()
            from.removeFromParent()
            
            superview?.addSubview(to.view)
            to.didMove(toParent: parent)
        }
    }
}

