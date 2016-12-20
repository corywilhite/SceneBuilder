//
//  ViralSwitch.swift
//  SceneBuilder
//
//  Created by Cory Wilhite on 12/19/16.
//  Copyright © 2016 Cory Wilhite. All rights reserved.
//

/**
 *
 * Swift port of AMViralSwitch: https://github.com/andreamazz/ViralSwitch
 *
 *
 */

import UIKit

struct AnimationElement {
    let view: UIView
    let keyPath: String
    let fromValue: Any
    let toValue: Any
}

class ViralSwitch: UISwitch {
    
    typealias AnimationResponse = () -> Void
    
    var animationDuration: TimeInterval = 0
    var animationElementsOn: [AnimationElement] = []
    var animationElementsOff: [AnimationElement] = []
    var completionOn: AnimationResponse?
    var completionOff: AnimationResponse?
    
    private var shape = CAShapeLayer()
    private var radius: CGFloat = 0
    
    override func layoutSubviews() {
        guard let superview = superview else { return }
        
        let x = max(frame.midX, superview.frame.width - frame.midX)
        let y = max(frame.midY, superview.frame.height - frame.midY)
        radius = (x.squared + y.squared).squareRoot()
        
        shape.frame = CGRect(x: frame.midX - radius, y: frame.midY - radius, width: radius * 2, height: radius * 2)
        shape.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        shape.path = UIBezierPath(ovalIn: CGRect(x: 0, y: 0, width: radius * 2, height: radius * 2)).cgPath
    }
    
    let context = UnsafeMutableRawPointer.allocate(bytes: 0, alignedTo: 0)
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        superview?.clipsToBounds = true
        
        shape = CAShapeLayer()
        shape.fillColor = onTintColor?.cgColor
        shape.transform = CATransform3DMakeScale(0.0001, 0.0001, 0.0001)
        superview?.layer.insertSublayer(shape, at: 0)
        
        layer.borderColor = UIColor.white.cgColor
        layer.cornerRadius = frame.height / 2
        
        if superview != nil {
            addObserver(
                self,
                forKeyPath: "on",
                options: [.new],
                context: context
            )
        }
        
        addTarget(self, action: #selector(ViralSwitch.switchChanged(sender:)), for: .valueChanged)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard context == self.context else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        switchChanged(sender: self)
    }
    
    override func setOn(_ on: Bool, animated: Bool) {
        super.setOn(on, animated: animated)
        switchChanged(sender: self)
    }
    
    override var onTintColor: UIColor? {
        didSet {
            shape.fillColor = onTintColor?.cgColor
        }
    }
    
    func switchChanged(sender: UISwitch) {
        if sender.isOn {
            CATransaction.begin()
            CATransaction.setCompletionBlock(completionOn)
            
            shape.removeAnimation(forKey: "scaleDown")
            shape.removeAnimation(forKey: "borderDown")
            
            let scaleAnimation = animate(
                keyPath: "transform.scale",
                fromValue: NSValue(caTransform3D: CATransform3DMakeScale(0.0001, 0.0001, 0.0001)),
                toValue: NSValue(caTransform3D: CATransform3DMakeScale(1, 1, 1)),
                timing: kCAMediaTimingFunctionEaseIn
            )
            
            shape.add(scaleAnimation, forKey: "scaleUp")
            
            let borderAnimation = animate(keyPath: "borderWidth", fromValue: 0, toValue: 1, timing: kCAMediaTimingFunctionEaseIn)
            borderAnimation.isRemovedOnCompletion = false
            layer.add(borderAnimation, forKey: "borderUp")
            
            animateElements(from: animationElementsOn)
            CATransaction.commit()
            
        } else {
            
            CATransaction.begin()
            CATransaction.setCompletionBlock(completionOff)
            
            shape.removeAnimation(forKey: "scaleUp")
            shape.removeAnimation(forKey: "borderUp")
            
            let scaleAnimation = animate(
                keyPath: "transform.scale",
                fromValue: NSValue(caTransform3D: CATransform3DMakeScale(1, 1, 1)),
                toValue: NSValue(caTransform3D: CATransform3DMakeScale(0.0001, 0.0001, 0.0001)),
                timing: kCAMediaTimingFunctionEaseIn
            )
            
            shape.add(scaleAnimation, forKey: "scaleDown")
            
            let borderAnimation = animate(keyPath: "borderWidth", fromValue: 1, toValue: 0, timing: kCAMediaTimingFunctionEaseOut)
            borderAnimation.isRemovedOnCompletion = false
            layer.add(borderAnimation, forKey: "borderDown")
            
            animateElements(from: animationElementsOff)
            CATransaction.commit()
            
        }
    }
    
    func animateElements(from elements: [AnimationElement]) {
        for element in elements {
            
            if let label = element.view as? UILabel, let toColor = element.toValue as? UIColor, element.keyPath == "textColor" {
                
                UIView.transition(with: element.view, duration: 0.35, options: .transitionCrossDissolve, animations: {
                    label.textColor = toColor
                }, completion: nil)
                
            } else if let button = element.view as? UIButton, let toColor = element.toValue as? UIColor, element.keyPath == "tintColor" {
                
                UIView.transition(with: element.view, duration: 0.35, options: .transitionCrossDissolve, animations: { 
                    button.tintColor = toColor
                }, completion: nil)
                
            } else {
                
                let basicAnimation = animate(keyPath: element.keyPath, fromValue: element.fromValue, toValue: element.toValue, timing: kCAMediaTimingFunctionEaseIn)
                element.view.layer.add(basicAnimation, forKey: element.keyPath)
            }
            
        }
    }
    
    func animate(keyPath: String, fromValue: Any, toValue: Any, timing: String) -> CABasicAnimation {
        let animation = CABasicAnimation(keyPath: keyPath)
        animation.fromValue = fromValue
        animation.toValue = toValue
        animation.repeatCount = 1
        animation.timingFunction = CAMediaTimingFunction(name: timing)
        animation.isRemovedOnCompletion = false
        animation.fillMode = kCAFillModeForwards
        animation.duration = 0.35
        return animation
    }
    
    deinit {
        removeObserver(self, forKeyPath: "on", context: context)
    }
}
