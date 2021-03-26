import UIKit
import MetalKit
import simd

var context : CGContext?

extension UIImage {
    class func imageWithColor(_ color: UIColor, _ sz:CGFloat) -> UIImage {
    let rect: CGRect = CGRect(x: 0, y: 0, width: sz, height: sz)
    UIGraphicsBeginImageContextWithOptions(CGSize(width:sz, height:sz), false, 0)
    color.setFill()
    UIRectFill(rect)
    let image: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image!
  }
}

class LimView: UIImageView
{
    var circleImage:UIImage! = nil
    let queue = DispatchQueue(label: "Q")

    var gDevice:MTLDevice! = nil
    var commandQueue:MTLCommandQueue! = nil
    var fBuffer:MTLBuffer! = nil
    var cBuffer:MTLBuffer! = nil
    var outTexture: MTLTexture!
    var pipeLine:MTLComputePipelineState! = nil
    var numThreadgroups2 = MTLSize()
    var threadsPerGroup2 = MTLSize()

    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        gDevice = MTLCreateSystemDefaultDevice()

//        circleImage = UIColor.black.image(CGSize(width: 1024/2, height: 1024/2))
        circleImage = UIImage.imageWithColor(UIColor.black, 512.0)
            
        commandQueue = gDevice.makeCommandQueue()!
        fBuffer = gDevice?.makeBuffer(length:MemoryLayout<FinalCircles>.stride, options:.storageModeShared)
        cBuffer = gDevice?.makeBuffer(length:MemoryLayout<Control>.stride, options:.storageModeShared)
    }

    //MARK: -
    
    func updateImage() {
        queue.async {
            self.update()
            DispatchQueue.main.async { self.image = self.image(from: self.outTexture) }
        }
    }
    
    func update() {
        if pipeLine == nil {
            func buildPipeline(_ shaderFunction:String) -> MTLComputePipelineState {
                var result:MTLComputePipelineState!
                
                do {
                    let defaultLibrary = gDevice?.makeDefaultLibrary()
                    let prg = defaultLibrary?.makeFunction(name:shaderFunction)
                    result = try gDevice?.makeComputePipelineState(function: prg!)
                } catch { fatalError("Failed to setup " + shaderFunction) }
                
                return result
            }
            
            pipeLine = buildPipeline("drawCirclesShader")
            let threadExecutionWidth = pipeLine.threadExecutionWidth
            numThreadgroups2 = MTLSize(width:16, height:1, depth:1)
            threadsPerGroup2 = MTLSize(width:threadExecutionWidth, height:1, depth:1)
        }
        
        limGenerate(&finalCircles)
        
        let threadExecutionWidth = pipeLine.threadExecutionWidth
        let ntg = Int(ceil(Float(finalCircles.nfinal)/Float(threadExecutionWidth)))
        numThreadgroups2 = MTLSize(width:ntg, height:1, depth:1)
        threadsPerGroup2 = MTLSize(width:threadExecutionWidth, height:1, depth:1)

        fBuffer?.contents().copyMemory(from:&finalCircles, byteCount:MemoryLayout<FinalCircles>.stride)
        cBuffer?.contents().copyMemory(from:&control, byteCount:MemoryLayout<Control>.stride)

        outTexture = texture(from: circleImage) // image = all black before drawing session

        let commandBuffer = commandQueue.makeCommandBuffer()!
        let commandEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        commandEncoder.setComputePipelineState(pipeLine)
        commandEncoder.setTexture(outTexture, index: 0)
        commandEncoder.setBuffer(fBuffer, offset: 0, index: 0)
        commandEncoder.setBuffer(cBuffer, offset: 0, index: 1)
        commandEncoder.dispatchThreadgroups(numThreadgroups2, threadsPerThreadgroup:threadsPerGroup2)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    //MARK: -
    
    var ccenter = CGPoint()
    var count = Int32()
    var x = Float()
    var y = Float()
    var r = Float()

    override func draw(_ rect: CGRect) {
        UIColor.blue.setFill()
        UIBezierPath(rect:rect).fill()
    }
    
    var pt = CGPoint()
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            pt = touch.location(in: self)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            var npt = touch.location(in: self)
            npt.x -= pt.x
            npt.y -= pt.y
            vc.focusMovement(npt)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        pt.x = 0
        pt.y = 0
        vc.focusMovement(pt)
    }
    
    //MARK: -
    // edit Scheme, Options, Metal API Validation : Disabled
    //the fix is to turn off Metal API validation under Product -> Scheme -> Options
    
    func texture(from image: UIImage) -> MTLTexture {
        guard let cgImage = image.cgImage else { fatalError("Can't open image \(image)") }
        
        let textureLoader = MTKTextureLoader(device: self.gDevice)
        do {
            let textureOut = try textureLoader.newTexture(cgImage:cgImage)
            let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: textureOut.pixelFormat,
                width: textureOut.width,
                height: textureOut.height,
                mipmapped: false)
            outTexture = self.gDevice.makeTexture(descriptor: textureDescriptor)
            return textureOut
        }
        catch {
            fatalError("Can't load texture")
        }
    }
    
    func image(from texture: MTLTexture) -> UIImage {
        let bytesPerPixel:Int = 4
        let imageByteCount = texture.width * texture.height * bytesPerPixel
        let bytesPerRow = texture.width * bytesPerPixel
        var src = [UInt8](repeating: 0, count: Int(imageByteCount))
        
        let region = MTLRegionMake2D(0, 0, texture.width, texture.height)
        texture.getBytes(&src, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        let bitmapInfo = CGBitmapInfo(rawValue: (CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitsPerComponent = 8
        let context = CGContext(data: &src,
                                width: texture.width,
                                height: texture.height,
                                bitsPerComponent: bitsPerComponent,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        
        let dstImageFilter = context?.makeImage()
        
        return UIImage(cgImage: dstImageFilter!, scale: 0.0, orientation: UIImageOrientation.up)
    }
}

extension UIColor {
    func image(_ size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { rendererContext in
            self.setFill()
            rendererContext.fill(CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }
    }
}
