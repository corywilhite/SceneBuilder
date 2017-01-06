//
//  LightsViewController.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/18/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import UIKit
import BoltsSwift


protocol LightCollectionCellDelegate: class {
    func didToggleOnOff(lightSwitch: UISwitch, for cell: LightCollectionViewCell)
    func didBeginChangingBrightness(for cell: LightCollectionViewCell)
    func didChangeBrightness(value: Float, for cell: LightCollectionViewCell)
    func didEndChangingBrightness(for cell: LightCollectionViewCell)
}

private extension UISlider {
    var floorValue: Float {
        return floor(value)
    }
}

class LightCollectionViewCell: UICollectionViewCell {

    weak var delegate: LightCollectionCellDelegate?
    
    @IBOutlet weak var titleLabel: UILabel! {
        didSet {
            titleLabel.textColor = .white
        }
    }
    
    @IBOutlet weak var brightnessLabel: UILabel! {
        didSet {
            brightnessLabel.textColor = .white
        }
    }
    @IBOutlet weak var onOffSwitch: UISwitch! {
        didSet {
            onOffSwitch.addTarget(self, action: #selector(onOffSwitchToggled(sender:)), for: .valueChanged)
        }
    }
    @IBOutlet weak var brightnessSlider: UISlider! {
        didSet {
            brightnessSlider.addTarget(self, action: #selector(brightnessSliderDidBeginValueChange(sender:)), for: .touchDown)
            brightnessSlider.addTarget(self, action: #selector(brightnessSliderValueChanged(sender:)), for: .valueChanged)
            brightnessSlider.addTarget(self, action: #selector(brightnessSliderDidEndValueChange(sender:)), for: [.touchUpInside, .touchUpOutside, .touchCancel])
            brightnessSlider.minimumValue = 0
            brightnessSlider.maximumValue = 254
            
        }
    }
    
    func configure(light: Light) {
        titleLabel.text = light.name
        backgroundColor = light.state.isOn ? light.currentColor : .lightGray
        
        brightnessLabel.text = "\(light.state.brightness)"
        brightnessSlider.value = Float(light.state.brightness)
        onOffSwitch.onTintColor = .green
        
        onOffSwitch.isOn = light.state.isOn
    }
    
    func onOffSwitchToggled(sender: UISwitch) {
        delegate?.didToggleOnOff(lightSwitch: sender, for: self)
    }
    
    func brightnessSliderDidBeginValueChange(sender: UISlider) {
        delegate?.didBeginChangingBrightness(for: self)
    }
    
    func brightnessSliderDidEndValueChange(sender: UISlider) {
        delegate?.didEndChangingBrightness(for: self)
    }
    
    func brightnessSliderValueChanged(sender: UISlider) {
        brightnessLabel.text = "\(sender.floorValue)"
        delegate?.didChangeBrightness(value: sender.floorValue, for: self)
    }
    
    class var identifier: String {
        return String(describing: self)
    }
    
    class var nib: UINib {
        return UINib(nibName: identifier, bundle: .main)
    }
}

class LightsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LightCollectionCellDelegate {
    
    var lights: [Light] = []
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(LightCollectionViewCell.nib, forCellWithReuseIdentifier: LightCollectionViewCell.identifier)
        }
    }
    
    let api: HueAPI
    
    init(api: HueAPI) {
        self.api = api
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not supported initializer. user init(user:)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.api.getLights().continueOnSuccessWith { [weak self] (lights) -> Void in
            self?.lights = lights
            self?.collectionView.reloadData()
        }
        
    }
    
    // MARK: - UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return lights.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: LightCollectionViewCell.identifier, for: indexPath) as! LightCollectionViewCell
        let light = lights[indexPath.item]
        cell.configure(light: light)
        cell.delegate = self
        return cell
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 300, height: 150)
    }
    
    // MARK: - LightCollectionCellDelegate
    
    func didToggleOnOff(lightSwitch: UISwitch, for cell: LightCollectionViewCell) {
        
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let light = lights[indexPath.item]
        
        let animateTo: UIColor
        
        if lightSwitch.isOn {
            animateTo = light.currentColor
        } else {
            animateTo = .lightGray
        }
        
        UIView.animate(withDuration: 1) {
            cell.backgroundColor = animateTo
        }
        
        let task = lightSwitch.isOn ? api.turnOn(light: light) : api.turnOff(light: light)
        
        update(light: light, at: indexPath, with: api, after: task)
    }
    
    func didBeginChangingBrightness(for cell: LightCollectionViewCell) {
        print("begin")
    }
    
    func didChangeBrightness(value: Float, for cell: LightCollectionViewCell) {
        print("changed to: \(value)")
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let light = lights[indexPath.item]
        
        api.changeBrightness(for: light, to: Int(value)).continueOnSuccessWith {
            print("changed \(light)")
        }
    }
    
    func update<T>(light: Light, at indexPath: IndexPath, with api: HueAPI, after task: Task<T>) {
        task.continueOnSuccessWithTask { _ in
            return api.getState(light: light)
        }.continueOnSuccessWith { [weak self] light in
                self?.lights[indexPath.item] = light
        }
    }
    
    func didEndChangingBrightness(for cell: LightCollectionViewCell) {
        
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let light = lights[indexPath.item]
        
        update(light: light, at: indexPath, with: api, after: Task({}))
        
        print("ended")
    }
    
}
