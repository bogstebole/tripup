import Foundation
import Vision
import CoreImage

let args = CommandLine.arguments
guard args.count == 3, let input = CIImage(contentsOf: URL(fileURLWithPath: args[1])) else {
    print("usage: lift <in> <out>"); exit(1)
}
let handler = VNImageRequestHandler(ciImage: input)
let request = VNGenerateForegroundInstanceMaskRequest()
do {
    try handler.perform([request])
    guard let result = request.results?.first else { print("no subject found"); exit(2) }
    let buffer = try result.generateMaskedImage(ofInstances: result.allInstances, from: handler, croppedToInstancesExtent: true)
    let out = CIImage(cvPixelBuffer: buffer)
    try CIContext().writePNGRepresentation(of: out, to: URL(fileURLWithPath: args[2]), format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
    print("instances: \(result.allInstances.count), size: \(Int(out.extent.width))x\(Int(out.extent.height))")
} catch {
    print("error: \(error)"); exit(3)
}
