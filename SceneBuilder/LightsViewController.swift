//
//  LightsViewController.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/18/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

import UIKit



protocol LightCollectionCellDelegate: class {
    func didToggleOnOff(switch: ViralSwitch, for cell: LightCollectionViewCell)
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
    @IBOutlet weak var onOffSwitch: ViralSwitch! {
        didSet {
            
            onOffSwitch.addTarget(self, action: #selector(onOffSwitchToggled(sender:)), for: .valueChanged)
        }
    }
    
    func configure(light: Light) {
        titleLabel.text = light.name
        backgroundColor = .lightGray
        
        brightnessLabel.text = "\(light.state.brightness)"
        
        onOffSwitch.onTintColor = ColorUtility.color(
            from: light.state.colorspaceCoordinate,
            brightness: light.state.brightness,
            model: light.modelId
        )
        
        onOffSwitch.isOn = light.state.isOn
    }
    
    func onOffSwitchToggled(sender: ViralSwitch) {
        delegate?.didToggleOnOff(switch: sender, for: self)
    }
    
    class var identifier: String {
        return String(describing: self)
    }
    
    class var nib: UINib {
        return UINib(nibName: identifier, bundle: .main)
    }
}

class LightsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LightCollectionCellDelegate {
    
    let user: WhitelistUser
    var lights: [Light] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(LightCollectionViewCell.nib, forCellWithReuseIdentifier: LightCollectionViewCell.identifier)
        }
    }
    
    var api: HueAPI?
    
    init(user: WhitelistUser) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not supported initializer. user init(user:)")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BridgeManager
            .findBridges()
            .continueOnSuccessWith(continuation: { $0.first! } )
            .continueOnSuccessWith(continuation: { info -> HueAPI in
                let newAPI = HueAPI(configuration: info, user: self.user)
                self.api = newAPI
                return newAPI
            })
            .continueOnSuccessWithTask(continuation: { $0.getLights() })
            .continueOnSuccessWith { (lights) -> Void in
                self.lights = lights
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
    
    func didToggleOnOff(switch: ViralSwitch, for cell: LightCollectionViewCell) {
        
        guard let indexPath = collectionView.indexPath(for: cell) else { return }
        let light = lights[indexPath.item]
        
        let task = `switch`.isOn ? self.api?.turnOn(light: light) : self.api?.turnOff(light: light)
        
        task?.continueOnSuccessWith(continuation: {
            print("success")
        })
    }
    
}
