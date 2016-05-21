//
//  CircleMenu.swift
//  ButtonTest
//
// Copyright (c) 18/01/16. Ramotion Inc. (http://ramotion.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import UIKit

// MARK: helpers

@warn_unused_result
public func Init<Type>(value: Type, @noescape block: (object: Type) -> Void) -> Type {
  block(object: value)
  return value
}

// MARK: Protocol

@objc public protocol CircleMenuDelegate {
  
  // don't change button.tag
  optional func circleMenu(circleMenu: CircleMenu, willDisplay button: CircleMenuButton, atIndex: Int)
  
  // call before animation
  optional func circleMenu(circleMenu: CircleMenu, buttonWillSelected button: CircleMenuButton, atIndex: Int)
  
  // call after animation
  optional func circleMenu(circleMenu: CircleMenu, buttonDidSelected button: CircleMenuButton, atIndex: Int)
}

// MARK: CircleMenu
public class CircleMenu: UIButton {
  
  // MARK: properties
  
  @IBInspectable public var buttonsCount: Int = 3
  @IBInspectable public var duration: Double  = 2 // circle animation duration
  @IBInspectable public var distance: Float   = 100 // distance between center button and buttons
  @IBInspectable public var showDelay: Double = 0 // delay between show buttons
  
    var gradientView: GradientView!
  @IBOutlet weak public var delegate: AnyObject? //CircleMenuDelegate?
  
  var buttons: [CircleMenuButton]?
  
  private var customNormalIconView: UIImageView!
  private var customSelectedIconView: UIImageView!
  
  // MARK: life cycle
  public init(frame: CGRect, normalIcon: String?, selectedIcon: String?, buttonsCount: Int = 3, duration: Double = 2,
    distance: Float = 100) {
      super.init(frame: frame)
      
      if let icon = normalIcon {
        setImage(UIImage(named: icon), forState: .Normal)
      }
      
      if let icon = selectedIcon {
        setImage(UIImage(named: icon), forState: .Selected)
      }
      
      self.buttonsCount = buttonsCount
      self.duration     = duration
      self.distance     = distance
    
    
      commonInit()
  }
  
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    
    commonInit()
  }
  
  private func commonInit() {
    addActions()
    
    
    customNormalIconView = addCustomImageView(state: .Normal)
    
    customSelectedIconView = addCustomImageView(state: .Selected)
    if customSelectedIconView != nil {
      customSelectedIconView.alpha = 0
    }
    setImage(UIImage(), forState: .Normal)
    setImage(UIImage(), forState: .Selected)
  }
  
  // MARK: public
  
  public func hideButtons(duration: Double, hideDelay: Double = 0) {
    if buttons == nil {
      return
    }
    
    buttonsAnimationIsShow(isShow: false, duration: duration, hideDelay: hideDelay)
    removeGradientView()
    tapBounceAnimation()
    tapRotatedAnimation(0.3, isSelected: false)
  }

  
  // MARK: create
  
  private func createButtons() -> [CircleMenuButton] {
    var buttons = [CircleMenuButton]()
    
    let step: Float = 360.0 / Float(self.buttonsCount)
    for index in 0..<self.buttonsCount {
      
      let angle: Float = Float(index) * step
      let distance = Float(self.bounds.size.height/2.0)
      let button = Init(CircleMenuButton(size: self.bounds.size, circleMenu: self, distance:distance, angle: angle)) {
          $0.tag = index
          $0.addTarget(self, action: #selector(CircleMenu.buttonHandler(_:)), forControlEvents: UIControlEvents.TouchUpInside)
          $0.alpha = 0
      }
      buttons.append(button)
    }
    return buttons
  }
  
  private func addCustomImageView(state state: UIControlState) -> UIImageView? {
    guard let image = imageForState(state) else {
      return nil
    }
    
    let iconView = Init(UIImageView(image: image)) {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.contentMode                               = .Center
      $0.userInteractionEnabled                    = false
    }
    addSubview(iconView)
    
    // added constraints
    iconView.addConstraint(NSLayoutConstraint(item: iconView, attribute: .Height, relatedBy: .Equal, toItem: nil,
      attribute: .Height, multiplier: 1, constant: bounds.size.height))
    
    iconView.addConstraint(NSLayoutConstraint(item: iconView, attribute: .Width, relatedBy: .Equal, toItem: nil,
      attribute: .Width, multiplier: 1, constant: bounds.size.width))
    
    addConstraint(NSLayoutConstraint(item: self, attribute: .CenterX, relatedBy: .Equal, toItem: iconView,
      attribute: .CenterX, multiplier: 1, constant:0))
    
    addConstraint(NSLayoutConstraint(item: self, attribute: .CenterY, relatedBy: .Equal, toItem: iconView,
      attribute: .CenterY, multiplier: 1, constant:0))
    
    return iconView
  }
  
  // MARK: configure
  
  private func addActions() {
    self.addTarget(self, action: #selector(CircleMenu.onTap), forControlEvents: UIControlEvents.TouchUpInside)
  }
  
  // MARK: helpers
  
  public func buttonsIsShown() -> Bool {
    guard let buttons = self.buttons else {
      return false
    }
    
    for button in buttons {
      if button.alpha == 0 {
        return false
      }
    }
    return true
  }
  
  // MARK: actions
  
  func onTap() {
    if buttonsIsShown() == false {
      buttons = createButtons()
    }
    let isShow = !buttonsIsShown()
    let duration  = isShow ? 0.5 : 0.2
    buttonsAnimationIsShow(isShow: isShow, duration: duration)
    
    tapBounceAnimation()
    tapRotatedAnimation(0.3, isSelected: isShow)
   
  }
  
  func buttonHandler(sender: CircleMenuButton) {
    delegate?.circleMenu?(self, buttonWillSelected: sender, atIndex: sender.tag)
    
    let circle = CircleMenuLoader(radius: CGFloat(distance), strokeWidth: bounds.size.height, circleMenu: self,
      color: sender.backgroundColor)
    
    if let container = sender.container { // rotation animation
      sender.rotationLayerAnimation(container.angleZ + 360, duration: duration)
      container.superview?.bringSubviewToFront(container)
    }
    
    if let aButtons = buttons {
      circle.fillAnimation(duration, startAngle: -90 + Float(360 / aButtons.count) * Float(sender.tag))
      circle.hideAnimation(0.5, delay: duration)
      
      hideCenterButton(duration: 0.3)
      
      buttonsAnimationIsShow(isShow: false, duration: 0, hideDelay: duration)
      showCenterButton(duration: 0.525, delay: duration)
      
      if customNormalIconView != nil && customSelectedIconView != nil {
        let dispatchTime: dispatch_time_t = dispatch_time(
          DISPATCH_TIME_NOW,
          Int64(duration * Double(NSEC_PER_SEC)))
        
        dispatch_after(dispatchTime, dispatch_get_main_queue(), {
          self.delegate?.circleMenu?(self, buttonDidSelected: sender, atIndex: sender.tag)
        })
      }
    }
  }
  
    private func showGradientView(){
        gradientView.fadeIn()
    }
    private func removeGradientView(){
       
        gradientView.fadeOut()
        
        
    }
  // MARK: animations
  
  private func buttonsAnimationIsShow(isShow isShow: Bool, duration: Double, hideDelay: Double = 0) {
    guard let buttons = self.buttons else {
      return
    }
    
 
    let step: Float = 360.0 / Float(self.buttonsCount)
    for index in 0..<self.buttonsCount {
      let button       = buttons[index]
      let angle: Float = Float(index) * step
      if isShow == true {
        delegate?.circleMenu?(self, willDisplay: button, atIndex: index)
       
        if gradientView == nil {
            gradientView = GradientView(frame: CGRectMake(0,0, (superview?.bounds.width)!, (superview?.bounds.height)!))
            gradientView.colors = [UIColor(hue: 11/360, saturation: 73/100, brightness: 83/100, alpha: 0.7), UIColor(hue: 337/360, saturation: 69/100, brightness: 65/100, alpha: 0.7)]
            gradientView.backgroundColor = UIColor.clearColor()
            gradientView.alpha = 0
            self.superview!.insertSubview(gradientView, atIndex: (superview?.subviews.indexOf(self))! - self.buttonsCount)
        }
        showGradientView()
       
        button.rotatedZ(angle: angle, animated: false, delay: Double(index) * showDelay)
        button.showAnimation(distance: distance, duration: duration, delay: Double(index) * showDelay)
      } else {
        button.hideAnimation(
          distance: Float(self.bounds.size.height / 2.0),
          duration: duration, delay: hideDelay)
      }
    }
    if isShow == false { // hide buttons and remove
   
      self.buttons = nil
         removeGradientView()
    }
  }
  
  private func tapBounceAnimation() {
    self.transform = CGAffineTransformMakeScale(0.9, 0.9)
    UIView.animateWithDuration(0.5, delay: 0, usingSpringWithDamping: 0.3, initialSpringVelocity: 5,
      options: UIViewAnimationOptions.CurveLinear,
      animations: { () -> Void in
        self.transform = CGAffineTransformMakeScale(1, 1)
      },
      completion: nil)
  }
  
  private func tapRotatedAnimation(duration: Float, isSelected: Bool) {
    
    let addAnimations: (view: UIImageView, isShow: Bool) -> () = { (view, isShow) in
      var toAngle: Float   = 180.0
      var fromAngle: Float = 0
      var fromScale        = 1.0
      var toScale          = 0.2
      var fromOpacity      = 1
      var toOpacity        = 0
      if isShow == true {
        toAngle     = 0
        fromAngle   = -180
        fromScale   = 0.2
        toScale     = 1.0
        fromOpacity = 0
        toOpacity   = 1
      }
      
      let rotation = Init(CABasicAnimation(keyPath: "transform.rotation")) {
        $0.duration       = NSTimeInterval(duration)
        $0.toValue        = (toAngle.degrees)
        $0.fromValue      = (fromAngle.degrees)
        $0.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      }
      let fade = Init(CABasicAnimation(keyPath: "opacity")) {
        $0.duration            = NSTimeInterval(duration)
        $0.fromValue           = fromOpacity
        $0.toValue             = toOpacity
        $0.timingFunction      = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        $0.fillMode            = kCAFillModeForwards
        $0.removedOnCompletion = false
      }
      let scale = Init(CABasicAnimation(keyPath: "transform.scale")) {
        $0.duration       = NSTimeInterval(duration)
        $0.toValue        = toScale
        $0.fromValue      = fromScale
        $0.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      }
      
      view.layer.addAnimation(rotation, forKey: nil)
      view.layer.addAnimation(fade, forKey: nil)
      view.layer.addAnimation(scale, forKey: nil)
    }
    
    if customNormalIconView != nil && customSelectedIconView != nil {
      addAnimations(view: customNormalIconView, isShow: !isSelected)
      addAnimations(view: customSelectedIconView, isShow: isSelected)
    }
    selected = isSelected
    self.alpha = isSelected ? 0.3 : 1
  }
  
  private func hideCenterButton(duration duration: Double, delay: Double = 0) {
    UIView.animateWithDuration( NSTimeInterval(duration), delay: NSTimeInterval(delay),
      options: UIViewAnimationOptions.CurveEaseOut,
      animations: { () -> Void in
        self.transform = CGAffineTransformMakeScale(0.001, 0.001)
      }, completion: nil)
    removeGradientView()
  }
  
  private func showCenterButton(duration duration: Float, delay: Double) {
    UIView.animateWithDuration( NSTimeInterval(duration), delay: NSTimeInterval(delay), usingSpringWithDamping: 0.78,
      initialSpringVelocity: 0, options: UIViewAnimationOptions.CurveLinear,
      animations: { () -> Void in
        self.transform = CGAffineTransformMakeScale(1, 1)
        self.alpha     = 1
      },
      completion: nil)
    
    let rotation = Init(CASpringAnimation(keyPath: "transform.rotation")) {
      $0.duration        = NSTimeInterval(1.5)
      $0.toValue         = (0)
      $0.fromValue       = (Float(-180).degrees)
      $0.damping         = 10
            $0.initialVelocity = 0
      $0.beginTime       = CACurrentMediaTime() + delay
    }
    let fade = Init(CABasicAnimation(keyPath: "opacity")) {
      $0.duration            = NSTimeInterval(0.01)
      $0.toValue             = 0
      $0.timingFunction      = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      $0.fillMode            = kCAFillModeForwards
      $0.removedOnCompletion = false
      $0.beginTime           = CACurrentMediaTime() + delay
    }
    let show = Init(CABasicAnimation(keyPath: "opacity")) {
      $0.duration            = NSTimeInterval(duration)
      $0.toValue             = 1
      $0.timingFunction      = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
      $0.fillMode            = kCAFillModeForwards
      $0.removedOnCompletion = false
      $0.beginTime           = CACurrentMediaTime() + delay
    }
    
    if customNormalIconView != nil {
      customNormalIconView.layer.addAnimation(rotation, forKey: nil)
      customNormalIconView.layer.addAnimation(show, forKey: nil)
    }
    
    if customSelectedIconView != nil {
      customSelectedIconView.layer.addAnimation(fade, forKey: nil)
    }
  }
}

// MARK: extension

extension Float {
  var radians: Float {
    return self * (Float(180) / Float(M_PI))
  }
  
  var degrees: Float {
    return self  * Float(M_PI) / 180.0
  }
}

extension UIView {
  
  var angleZ: Float {
    let radians: Float = atan2(Float(self.transform.b), Float(self.transform.a))
    return radians.radians
  }
}
public extension UIView {
    
    /**
     Fade in a view with a duration
     
     - parameter duration: custom animation duration
     */
    func fadeIn(duration duration: NSTimeInterval = 0.3) {
        UIView.animateWithDuration(duration, animations: {
            self.alpha = 1.0
        })
    }
    
    /**
     Fade out a view with a duration
     
     - parameter duration: custom animation duration
     */
    func fadeOut(duration duration: NSTimeInterval = 0.3) {
        UIView.animateWithDuration(duration, animations: {
            self.alpha = 0.0
            
        })

    }
    
}

@IBDesignable
public class GradientView: UIView {
    
    // MARK: - Types
    
    /// The mode of the gradient.
    public enum Type {
        /// A linear gradient.
        case Linear
        
        /// A radial gradient.
        case Radial
    }
    
    
    /// The direction of the gradient.
    public enum Direction {
        /// The gradient is vertical.
        case Vertical
        
        /// The gradient is horizontal
        case Horizontal
    }
    
    
    // MARK: - Properties
    
    /// An optional array of `UIColor` objects used to draw the gradient. If the value is `nil`, the `backgroundColor`
    /// will be drawn instead of a gradient. The default is `nil`.
    public var colors: [UIColor]? {
        didSet {
            updateGradient()
        }
    }
    
    /// An array of `UIColor` objects used to draw the dimmed gradient. If the value is `nil`, `colors` will be
    /// converted to grayscale. This will use the same `locations` as `colors`. If length of arrays don't match, bad
    /// things will happen. You must make sure the number of dimmed colors equals the number of regular colors.
    ///
    /// The default is `nil`.
    public var dimmedColors: [UIColor]? {
        didSet {
            updateGradient()
        }
    }
    
    /// Automatically dim gradient colors when prompted by the system (i.e. when an alert is shown).
    ///
    /// The default is `true`.
    public var automaticallyDims: Bool = true
    
    /// An optional array of `CGFloat`s defining the location of each gradient stop.
    ///
    /// The gradient stops are specified as values between `0` and `1`. The values must be monotonically increasing. If
    /// `nil`, the stops are spread uniformly across the range.
    ///
    /// Defaults to `nil`.
    public var locations: [CGFloat]? {
        didSet {
            updateGradient()
        }
    }
    
    /// The mode of the gradient. The default is `.Linear`.
    @IBInspectable
    public var mode: Type = .Linear {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The direction of the gradient. Only valid for the `Mode.Linear` mode. The default is `.Vertical`.
    @IBInspectable
    public var direction: Direction = .Vertical {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// 1px borders will be drawn instead of 1pt borders. The default is `true`.
    @IBInspectable
    public var drawsThinBorders: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The top border color. The default is `nil`.
    @IBInspectable
    public var topBorderColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The right border color. The default is `nil`.
    @IBInspectable
    public var rightBorderColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    ///  The bottom border color. The default is `nil`.
    @IBInspectable
    public var bottomBorderColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    /// The left border color. The default is `nil`.
    @IBInspectable
    public var leftBorderColor: UIColor? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    
    // MARK: - UIView
    
    override public func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        let size = bounds.size
        
        // Gradient
        if let gradient = gradient {
            let options: CGGradientDrawingOptions = [.DrawsAfterEndLocation]
            
            if mode == .Linear {
                let startPoint = CGPointZero
                let endPoint = direction == .Vertical ? CGPoint(x: 0, y: size.height) : CGPoint(x: size.width, y: 0)
                CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, options)
            } else {
                let center = CGPoint(x: bounds.midX, y: bounds.midY)
                CGContextDrawRadialGradient(context, gradient, center, 0, center, min(size.width, size.height) / 2, options)
            }
        }
        
        let screen: UIScreen = window?.screen ?? UIScreen.mainScreen()
        let borderWidth: CGFloat = drawsThinBorders ? 1.0 / screen.scale : 1.0
        
        // Top border
        if let color = topBorderColor {
            CGContextSetFillColorWithColor(context, color.CGColor)
            CGContextFillRect(context, CGRect(x: 0, y: 0, width: size.width, height: borderWidth))
        }
        
        let sideY: CGFloat = topBorderColor != nil ? borderWidth : 0
        let sideHeight: CGFloat = size.height - sideY - (bottomBorderColor != nil ? borderWidth : 0)
        
        // Right border
        if let color = rightBorderColor {
            CGContextSetFillColorWithColor(context, color.CGColor)
            CGContextFillRect(context, CGRect(x: size.width - borderWidth, y: sideY, width: borderWidth, height: sideHeight))
        }
        
        // Bottom border
        if let color = bottomBorderColor {
            CGContextSetFillColorWithColor(context, color.CGColor)
            CGContextFillRect(context, CGRect(x: 0, y: size.height - borderWidth, width: size.width, height: borderWidth))
        }
        
        // Left border
        if let color = leftBorderColor {
            CGContextSetFillColorWithColor(context, color.CGColor)
            CGContextFillRect(context, CGRect(x: 0, y: sideY, width: borderWidth, height: sideHeight))
        }
    }
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        
        if automaticallyDims {
            updateGradient()
        }
    }
    
    override public func didMoveToWindow() {
        super.didMoveToWindow()
        contentMode = .Redraw
    }
    
    
    // MARK: - Private
    
    private var gradient: CGGradientRef?
    
    private func updateGradient() {
        gradient = nil
        setNeedsDisplay()
        
        let colors = gradientColors()
        if let colors = colors {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let colorSpaceModel = CGColorSpaceGetModel(colorSpace)
            
            let gradientColors: NSArray = colors.map { (color: UIColor) -> AnyObject! in
                let cgColor = color.CGColor
                let cgColorSpace = CGColorGetColorSpace(cgColor)
                
                // The color's color space is RGB, simply add it.
                if CGColorSpaceGetModel(cgColorSpace).rawValue == colorSpaceModel.rawValue {
                    return cgColor as AnyObject!
                }
                
                // Convert to RGB. There may be a more efficient way to do this.
                var red: CGFloat = 0
                var blue: CGFloat = 0
                var green: CGFloat = 0
                var alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                return UIColor(red: red, green: green, blue: blue, alpha: alpha).CGColor as AnyObject!
            }
            
            // TODO: This is ugly. Surely there is a way to make this more concise.
            if let locations = locations {
                gradient = CGGradientCreateWithColors(colorSpace, gradientColors, locations)
            } else {
                gradient = CGGradientCreateWithColors(colorSpace, gradientColors, nil)
            }
        }
    }
    
    private func gradientColors() -> [UIColor]? {
        if tintAdjustmentMode == .Dimmed {
            if let dimmedColors = dimmedColors {
                return dimmedColors
            }
            
            if automaticallyDims {
                if let colors = colors {
                    return colors.map {
                        var hue: CGFloat = 0
                        var brightness: CGFloat = 0
                        var alpha: CGFloat = 0
                        
                        $0.getHue(&hue, saturation: nil, brightness: &brightness, alpha: &alpha)
                        
                        return UIColor(hue: hue, saturation: 0, brightness: brightness, alpha: alpha)
                    }
                }
            }
        }
        
        return colors
    }
}