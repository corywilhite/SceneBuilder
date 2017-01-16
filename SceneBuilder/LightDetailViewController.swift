//
//  LightDetailViewController.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 1/14/17.
//  Copyright © 2017 Cory Wilhite. All rights reserved.
//

import UIKit

class LightDetailViewController: UIViewController {
    
    let light: Light
    let api: HueAPI
    
    @IBOutlet var colorContainer: UIView!
    @IBOutlet var brightnessSlider: UISlider!
    @IBOutlet var onOffSwitch: UISwitch!
    
    init(light: Light, api: HueAPI) {
        self.light = light
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissController))
        swipeGesture.numberOfTouchesRequired = 3
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func transferState(from cell: LightCollectionViewCell) {
        brightnessSlider.minimumValue = cell.brightnessSlider.minimumValue
        brightnessSlider.maximumValue = cell.brightnessSlider.maximumValue
        brightnessSlider.value = cell.brightnessSlider.value
        colorContainer.backgroundColor = cell.backgroundColor
        onOffSwitch.isOn = cell.onOffSwitch.isOn
    }
    
    func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
}
