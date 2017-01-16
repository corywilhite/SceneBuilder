//
//  LightDetailViewController.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 1/14/17.
//  Copyright © 2017 Cory Wilhite. All rights reserved.
//

import UIKit

protocol LightDetailViewControllerDelegate: class {
    func didUpdate(light: Light, from detailController: LightDetailViewController)
}

class LightDetailViewController: UIViewController {
    
    var light: Light
    let api: HueAPI
    
    @IBOutlet weak var colorContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var brightnessSlider: UISlider!
    @IBOutlet weak var onOffSwitch: UISwitch!
    
    weak var delegate: LightDetailViewControllerDelegate?
    
    init(light: Light, api: HueAPI) {
        self.light = light
        self.api = api
        super.init(nibName: nil, bundle: nil)
        _ = view
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        onOffSwitch.addTarget(self, action: #selector(onOffSwitchToggled(sender:)), for: .valueChanged)
        brightnessSlider.addTarget(self, action: #selector(brightnessSliderDidBeginValueChange(sender:)), for: .touchDown)
        brightnessSlider.addTarget(self, action: #selector(brightnessSliderValueChanged(sender:)), for: .valueChanged)
        brightnessSlider.addTarget(self, action: #selector(brightnessSliderDidEndValueChanged(sender:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
        brightnessSlider.minimumValue = 0
        brightnessSlider.maximumValue = 254
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(dismissController))
        swipeGesture.numberOfTouchesRequired = 3
        swipeGesture.direction = .down
        view.addGestureRecognizer(swipeGesture)
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func onOffSwitchToggled(sender: UISwitch) {
        
        let animateTo: UIColor
        
        if sender.isOn {
            animateTo = light.currentColor
        } else {
            animateTo = .lightGray
        }
        
        UIView.animate(withDuration: 1) { 
            self.colorContainer.backgroundColor = animateTo
        }
        
        let task = sender.isOn ? api.turnOn(light: light) : api.turnOff(light: light)
        
        task.continueOnSuccessWithTask { _ in
            return self.api.getState(light: self.light)
        }.continueOnSuccessWith { light in
            self.light = light
            self.delegate?.didUpdate(light: light, from: self)
        }
    }
    
    func brightnessSliderDidBeginValueChange(sender: UISlider) {
        
    }
    
    func brightnessSliderValueChanged(sender: UISlider) {
        api.changeBrightness(for: light, to: Int(sender.value))
    }
    
    func brightnessSliderDidEndValueChanged(sender: UISlider) {
        api.getState(light: light).continueOnSuccessWith { light in
            self.light = light
            self.delegate?.didUpdate(light: light, from: self)
        }
    }
    
    func configure(light: Light) {
        titleLabel.text = light.name
        colorContainer.backgroundColor = light.state.isOn ? light.currentColor : .lightGray
        
        brightnessSlider.value = Float(light.state.brightness)
        
        onOffSwitch.onTintColor = .green
        onOffSwitch.isOn = light.state.isOn
    }
    
    func dismissController() {
        dismiss(animated: true, completion: nil)
    }
    
}
