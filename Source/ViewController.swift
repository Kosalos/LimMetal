import UIKit
import Metal
import MetalKit

let kludgeAutoLayout:Bool = false
let scrnSz:[CGPoint] = [ CGPoint(x:768,y:1024), CGPoint(x:834,y:1112), CGPoint(x:1024,y:1366) ] // portrait
let scrnIndex = 0
let scrnLandscape:Bool = true

var vc:ViewController! = nil
var finalCircles = FinalCircles()
var control = Control()

class ViewController: UIViewController {
    var timer = Timer()
    var gIndex:Int32 = 0
    var dList:[DeltaView]! = nil
    var sList:[SliderView]! = nil
    let depthList:[Int32] = [ 2,3,4,5,7,10 ]

    @IBOutlet var limView: LimView!
    @IBOutlet var genSelect: UISegmentedControl!
    @IBOutlet var depthSelect: UISegmentedControl!
    @IBOutlet var genA: DeltaView!
    @IBOutlet var genB: DeltaView!
    @IBOutlet var genC: DeltaView!
    @IBOutlet var genD: DeltaView!
    @IBOutlet var genAB: DeltaView!
    @IBOutlet var genAB2: DeltaView!
    @IBOutlet var genCD: DeltaView!
    @IBOutlet var genCD2: DeltaView!
    @IBOutlet var sEpi: SliderView!
    @IBOutlet var resetButton: UIButton!
    @IBOutlet var activeButton: UIButton!
    @IBOutlet var saveLoadButton: UIButton!
    @IBOutlet var helpButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        vc = self
        
        dList = [ genA,genB,genC,genD,genAB,genAB2,genCD,genCD2 ]
        sList = [ sEpi ]
        
        setControlPointer(&control);
        control.xscale = 400
        
        reset()
        rotated()
    
        timer = Timer.scheduledTimer(timeInterval: 1.0/60.0, target:self, selector: #selector(timerHandler), userInfo: nil, repeats:true)
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: .UIDeviceOrientationDidChange, object: nil)
    }

    override var prefersStatusBarHidden: Bool { return true }

    //MARK: -

    func update() {
        control.yscale = control.xscale * control.ratio
        limView.updateImage()
    }
    
    //MARK: -

    func initializeGenWidgetPointers() {
        let gMin:Float = -3
        let gMax:Float = +3
        let gDiff:Float = gMax / 10
        genA.initializeFloats(AxPointer(gIndex), AyPointer(gIndex), gMin,gMax,gDiff,"A")
        genB.initializeFloats(BxPointer(gIndex), ByPointer(gIndex), gMin,gMax,gDiff,"B")
        genC.initializeFloats(CxPointer(gIndex), CyPointer(gIndex), gMin,gMax,gDiff,"C")
        genD.initializeFloats(DxPointer(gIndex), DyPointer(gIndex), gMin,gMax,gDiff,"D")

        genAB.initializeFloats(  AxPointer(gIndex), AyPointer(gIndex), gMin,gMax,gDiff,"A+B")
        genAB.initializeFloats2( BxPointer(gIndex), ByPointer(gIndex), genA,genB,+1)
        genAB2.initializeFloats( AxPointer(gIndex), AyPointer(gIndex), gMin,gMax,gDiff,"A-B")
        genAB2.initializeFloats2(BxPointer(gIndex), ByPointer(gIndex), genA,genB,-1)

        genCD.initializeFloats(  CxPointer(gIndex), CyPointer(gIndex), gMin,gMax,gDiff,"C+D")
        genCD.initializeFloats2( DxPointer(gIndex), DyPointer(gIndex), genC,genD,+1)
        genCD2.initializeFloats( CxPointer(gIndex), CyPointer(gIndex), gMin,gMax,gDiff,"C-D")
        genCD2.initializeFloats2(DxPointer(gIndex), DyPointer(gIndex), genC,genD,-1)

        sEpi.initializeFloat(&control.eps, .delta, 0.001, 0.01, 0.001, "epsilon")
        
        setActiveButtonColor()
    }
    
    @IBAction func resetButtonPressed(_ sender: UIButton) { reset() }
    
    func controlLoaded() {
        gIndex = 0
        genSelect.selectedSegmentIndex = Int(gIndex)
        
        depthSelect.selectedSegmentIndex = 5    // default depth = 10
        control.depth = depthList[depthSelect.selectedSegmentIndex]
        
        initializeGenWidgetPointers()
        update()
    }
    
    func reset() {
        removeAllFocus()
        limReset()
        controlLoaded()
    }

    @IBAction func activeButtonPressed(_ sender: UIButton) {
        let onoff = getActive(gIndex) > 0 ? 0 : 1
        
        setActive(gIndex,Int32(onoff))
        setActiveButtonColor()
        update()
    }

    @IBAction func selectChanged(_ sender: UISegmentedControl) {
        gIndex = Int32(sender.selectedSegmentIndex)
        initializeGenWidgetPointers()
        update()
    }

    @IBAction func depthChanged(_ sender: UISegmentedControl) {
        control.depth = depthList[sender.selectedSegmentIndex]
        update()
    }

    //MARK: -

    @objc func timerHandler() {
        var refresh = false
        for d in dList { if d.update() { refresh = true }}
        for s in sList { if s.update() { refresh = true }}
        if refresh { update() }
    }

    //MARK: -

    func removeAllFocus() {
        for s in sList { if s.hasFocus { s.hasFocus = false; s.setNeedsDisplay() }}
        for d in dList { if d.hasFocus { d.hasFocus = false; d.setNeedsDisplay() }}
    }
    
    func focusMovement(_ pt:CGPoint) {
        for s in sList { if s.hasFocus { s.focusMovement(pt); return }}
        for d in dList { if d.hasFocus { d.focusMovement(pt); return }}
    }

    func setActiveButtonColor() {
        let onoff = getActive(gIndex)
        activeButton.setTitleColor(onoff > 0 ? .green : .lightGray, for:.normal)
    }
    
    //MARK: -
    
    @objc func rotated() {
        var wxs = view.bounds.width
        var wys = view.bounds.height
        if kludgeAutoLayout {
            wxs = scrnLandscape ? scrnSz[scrnIndex].y : scrnSz[scrnIndex].x
            wys = scrnLandscape ? scrnSz[scrnIndex].x : scrnSz[scrnIndex].y
        }

        var x = CGFloat()
        var y = CGFloat()
        
        func frame(_ fxs:CGFloat, _ fys:CGFloat, _ dx:CGFloat, _ dy:CGFloat) -> CGRect {
            let r = CGRect(x:x, y:y, width:fxs, height:fys)
            x += dx; y += dy
            return r
        }
        
        limView.frame = CGRect(x:0, y:0, width:wxs, height:wys-170)
        control.ratio = Float(wxs) / Float(wys-170) // used when stretching drawing to fit UIImageView

        let leftEdge = wxs/2 - 360
        x = leftEdge
        y = wys - 155
        genSelect.frame = frame(200,35,240,0)
        activeButton.frame = frame(50,40,80,0)
        resetButton.frame = frame(50,40,80,0)
        saveLoadButton.frame = frame(80,40,110,0)
        helpButton.frame = frame(40,40,0,0)
        
        x = leftEdge
        y = wys - 115
        let gSz:CGFloat = 100
        let gHop:CGFloat = gSz+10
        genA.frame = frame(gSz,gSz,gHop,0)
        genB.frame = frame(gSz,gSz,gHop,0)
        genC.frame = frame(gSz,gSz,gHop,0)
        genD.frame = frame(gSz,gSz,gHop,0)
        sEpi.frame = frame(135,40,0,60)
        depthSelect.frame = frame(135,35,155,0)

        let x2 = x
        y = wys-115
        let gSz2:CGFloat = 70
        let ySz2:CGFloat = 45
        let yHop:CGFloat = ySz2 + 10
        genAB.frame = frame(gSz2,ySz2,0,yHop)
        genAB2.frame = frame(gSz2,ySz2,0,0)
        x = x2 + gSz2 + 10
        y = wys-115
        genCD.frame = frame(gSz2,ySz2,0,yHop)
        genCD2.frame = frame(gSz2,ySz2,0,0)

        if sList != nil {
            for s in sList { s.boundsChanged() }
            for d in dList { d.boundsChanged() }
        }
        
        update()
    }
    
    //MARK: -
    
    let scaleMin:Float = 20
    let scaleMax:Float = 1200
    var startPinch:Float = 0
    
    @IBAction func pinchGesture(_ sender: UIPinchGestureRecognizer) {
        if sender.state == .began { startPinch = control.xscale }
        control.xscale = fClamp(startPinch * Float(sender.scale),scaleMin,scaleMax)
        update()
    }
}

func fClamp(_ v:Float, _ min:Float, _ max:Float) -> Float {
    if v < min { return min }
    if v > max { return max }
    return v
}

