import UIKit

let limColor = UIColor(red:0.25, green:0.25, blue:0.2, alpha: 0.4)
let nrmColorFast = UIColor(red:0.35, green:0.2, blue:0.2, alpha: 0.4)
let nrmColorSlow = UIColor(red:0.2, green:0.25, blue:0.2, alpha: 0.4)
let widgetEdgeColor = UIColor.black
let textColor = UIColor.white

enum ValueType { case int32,float }
enum SliderType { case delta,direct,loop }

let highLightUnused:Float = 999

class SliderView: UIView {
    var context : CGContext?
    var scenter:Float = 0
    var swidth:Float = 0
    var ident:Int = 0
    var active = true
    var fastEdit = true
    var hasFocus = false

    var highLightValue = highLightUnused

    var valuePointer:UnsafeMutableRawPointer! = nil
    var valuetype:ValueType = .float
    var slidertype:SliderType = .delta
    var deltaValue:Float = 0
    var name:String = "name"

    var min:Float = 0
    var max:Float = 256
    let percentList:[CGFloat] = [ 0.20,0.22,0.25,0.28,0.32,0.37,0.43,0.48,0.52,0.55,0.57 ]
    
    func address<T>(of: UnsafePointer<T>) -> UInt { return UInt(bitPattern: of) }
    
    func initializeCommon() {
        boundsChanged()
        
        let tap1 = UITapGestureRecognizer(target: self, action: #selector(self.handleTap1(_:)))
        tap1.numberOfTapsRequired = 1
        addGestureRecognizer(tap1)
        
        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.handleTap2(_:)))
        tap2.numberOfTapsRequired = 2
        addGestureRecognizer(tap2)
        
        let tap3 = UITapGestureRecognizer(target: self, action: #selector(self.handleTap3(_:)))
        tap3.numberOfTapsRequired = 3
        addGestureRecognizer(tap3)
        
        isUserInteractionEnabled = true
        self.backgroundColor = .clear
    }
    
    func initializeInt32(_ v: inout Int32, _ sType:SliderType, _ vmin:Float, _ vmax:Float,  _ delta:Float, _ iname:String) {
        let valueAddress = address(of:&v)
        valuePointer = UnsafeMutableRawPointer(bitPattern:valueAddress)!
        valuetype = .int32
        slidertype = sType
        min = vmin
        max = vmax
        deltaValue = delta
        name = iname
        initializeCommon()
    }

    func initializeFloat(_ v: inout Float, _ sType:SliderType, _ vmin:Float, _ vmax:Float,  _ delta:Float, _ iname:String) {
        let valueAddress = address(of:&v)
        valuePointer = UnsafeMutableRawPointer(bitPattern:valueAddress)!
        valuetype = .float
        slidertype = sType
        min = vmin
        max = vmax
        deltaValue = delta
        name = iname
        initializeCommon()
    }

    func highlight(_ v:Float) {
        highLightValue = v
    }

    func setActive(_ v:Bool) {
        active = v
        setNeedsDisplay()
    }
    
    func percentX(_ percent:CGFloat) -> CGFloat { return CGFloat(bounds.size.width) * percent }
    
    func boundsChanged() {
        swidth = Float(bounds.width)
        scenter = swidth / 2
        setNeedsDisplay()
    }
    
    //MARK: ==================================
    
    @objc func handleTap1(_ sender: UITapGestureRecognizer) {
        vc.removeAllFocus()
        hasFocus = true
        
        delta = 0
        setNeedsDisplay()
    }
    
    @objc func handleTap2(_ sender: UITapGestureRecognizer) {
        fastEdit = !fastEdit
        
        delta = 0
        setNeedsDisplay()
    }
    
    @objc func handleTap3(_ sender: UITapGestureRecognizer) {
        if valuePointer == nil { return }
        
        let value:Float = highLightValue != highLightUnused ? highLightValue : 0

        switch valuetype {
        case .int32 : valuePointer.storeBytes(of:Int32(value), as:Int32.self)
        case .float : valuePointer.storeBytes(of:value, as:Float.self)
        }
        
        handleTap2(sender) // undo the double tap that was also recognized
    }
    
    //MARK: ==================================

    override func draw(_ rect: CGRect) {
        context = UIGraphicsGetCurrentContext()
        
        if !active {
            let G:CGFloat = 0.13        // color Lead
            UIColor(red:G, green:G, blue:G, alpha: 1).set()
            UIBezierPath(rect:bounds).fill()
            return
        }
        
        if fastEdit { nrmColorFast.set() } else { nrmColorSlow.set() }
        UIBezierPath(rect:bounds).fill()
        
        if isMinValue() {
            limColor.set()
            var r = bounds
            r.size.width /= 2
            UIBezierPath(rect:r).fill()
        }
        else if isMaxValue() { 
            limColor.set()
            var r = bounds
            r.origin.x += bounds.width/2
            r.size.width /= 2
            UIBezierPath(rect:r).fill()
        }
        
        // edge -------------------------------------------------
        context!.setStrokeColor(UIColor.black.cgColor)

        let path = UIBezierPath(rect:bounds)
        context!.setLineWidth(2)
        context!.addPath(path.cgPath)
        context!.strokePath()

        // value ------------------------------------------
        func formatted(_ v:Float) -> String { return String(format:"%6.4f",v) }
        func formatted2(_ v:Float) -> String { return String(format:"%7.5f",v) }
        func formatted3(_ v:Float) -> String { return String(format:"%d",Int(v)) }
        func formatted4(_ v:Float) -> String { return String(format:"%5.2f",v) }

        let vx = percentX(0.60)
        
        func valueColor(_ v:Float) -> UIColor {
            var c = UIColor.gray
            if v < 0 { c = UIColor.red } else if v > 0 { c = UIColor.green }
            return c
        }
      
        // cursor -------------------------------------------------
        let x = valueRatio() * bounds.width
        context!.setStrokeColor(widgetEdgeColor.cgColor)
        context!.setLineWidth(4)
        path.removeAllPoints()
        path.move(to: CGPoint(x:x, y:0))
        path.addLine(to: CGPoint(x:x, y:bounds.height))
        context!.addPath(path.cgPath)
        context!.strokePath()
        
        func coloredValue(_ v:Float) { drawText(context!,vx,8,valueColor(v),16, formatted(v)) }
        
        if valuePointer != nil {
            drawText(context!,10,8,textColor,16,name)
            
//            switch valuetype {
//            case .int32 :
//                let v:Int32 = valuePointer.load(as: Int32.self)
//                drawText(percentX(0.75),8,.gray,16, v.description)
//            case .float :
//                let v:Float = valuePointer.load(as: Float.self)
//                
//                if v > 100 {
//                    drawText(vx,8,.gray,16, formatted3(v))
//                }
//                else {
//                    coloredValue(v)
//                }
//            }
        }
        
        // highlight --------------------------------------
        
        if highLightValue != highLightUnused {
            let den = CGFloat(max - min)
            if den != 0 {
                let x:CGFloat = bounds.width * CGFloat(highLightValue - min) / den
                drawFilledCircle(context!,CGPoint(x:x,y:5),4,textColor.cgColor)
            }
        }

        if hasFocus {
            UIColor.red.setStroke()
            UIBezierPath(rect:bounds).stroke()
        }
    }
    
    var delta:Float = 0
    var touched = false

    //MARK: ==================================

    func getValue() -> Float {
        if valuePointer == nil { return 0 }
        var value:Float = 0
        
        switch valuetype {
        case .int32 : value = Float(valuePointer.load(as: Int32.self))
        case .float : value = valuePointer.load(as: Float.self)
        }

        return value
    }
    
    func isMinValue() -> Bool {
        if valuePointer == nil { return false }
        if slidertype == .loop { return false }

        return getValue() == min
    }
    
    func isMaxValue() -> Bool {
        if valuePointer == nil { return false }
        if slidertype == .loop { return false }
        
        return getValue() == max
    }
    
    func valueRatio() -> CGFloat {
        let den = max - min
        if den == 0 { return CGFloat(0) }
        return CGFloat((getValue() - min) / den )
    }
    
    //MARK: ==================================
    
    let scale:Float = 1   // speedMult
    
    func update() -> Bool {
        if valuePointer == nil || !active || !touched { return false }

        var value = getValue()
        
        if slidertype == .loop {
            value += delta * deltaValue
            if value < min { value += (max - min) } else
                if value > max { value -= (max - min) }
        }
        else {
            value = fClamp(value + delta * deltaValue * scale, min,max)
        }
        
        switch valuetype {
        case .int32 : valuePointer.storeBytes(of:Int32(value), as:Int32.self)
        case .float : valuePointer.storeBytes(of:value, as:Float.self)
        }
        
        setNeedsDisplay()
        return true
    }
    
    //MARK: ==================================

    func focusMovement(_ pt:CGPoint) {
        if pt.x == 0 { touched = false; return }
        
        delta = Float(pt.x) / 1000
        
        if !fastEdit {
            delta /= 100
        }
        
        touched = true
        setNeedsDisplay()
    }
    
    //MARK: ==================================

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if valuePointer == nil || !active { return }
        
        for t in touches {
            let pt = t.location(in: self)
            
            touched = true
            
            if slidertype == .direct {
                let value = fClamp(min + (max - min) * Float(pt.x) / swidth, min,max)

                switch valuetype {
                case .int32 : valuePointer.storeBytes(of:Int32(value), as:Int32.self)
                case .float : valuePointer.storeBytes(of:value, as:Float.self)
                }
            }
            else {
                delta = (Float(pt.x) - scenter) / swidth / 10
                
                if !fastEdit {
                    delta /= 100
                }
            }
            
            setNeedsDisplay()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) { touchesBegan(touches, with:event) }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { touched = false }
}

