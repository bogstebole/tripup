// Cut out only the main subject: the foreground instance under a point (default x 0.5, y 0.4 from top).
// usage: lift_main <in> <out> [x] [y]
import Foundation
import Vision
import CoreImage

let a = CommandLine.arguments
guard a.count >= 3, let input = CIImage(contentsOf: URL(fileURLWithPath: a[1])) else { print("usage: lift_main <in> <out> [x] [y]"); exit(1) }
let px = a.count > 3 ? Double(a[3])! : 0.5, py = a.count > 4 ? Double(a[4])! : 0.4
let handler = VNImageRequestHandler(ciImage: input)
let request = VNGenerateForegroundInstanceMaskRequest()
do {
    try handler.perform([request])
    guard let r = request.results?.first else { print("no subject found"); exit(2) }
    let mask = r.instanceMask
    CVPixelBufferLockBaseAddress(mask, .readOnly)
    let w = CVPixelBufferGetWidth(mask), h = CVPixelBufferGetHeight(mask), bpr = CVPixelBufferGetBytesPerRow(mask)
    let base = CVPixelBufferGetBaseAddress(mask)!.assumingMemoryBound(to: UInt8.self)
    var label = Int(base[Int(py * Double(h)) * bpr + Int(px * Double(w))])
    if label == 0 { // nothing under the point: take the largest instance
        var counts = [Int: Int]()
        for y in stride(from: 0, to: h, by: 4) { for x in stride(from: 0, to: w, by: 4) { let l = Int(base[y * bpr + x]); if l > 0 { counts[l, default: 0] += 1 } } }
        label = counts.max(by: { $0.value < $1.value })?.key ?? 0
    }
    CVPixelBufferUnlockBaseAddress(mask, .readOnly)
    let pick: IndexSet = label > 0 ? IndexSet(integer: label) : r.allInstances
    let buf = try r.generateMaskedImage(ofInstances: pick, from: handler, croppedToInstancesExtent: true)
    let out = CIImage(cvPixelBuffer: buf)
    try CIContext().writePNGRepresentation(of: out, to: URL(fileURLWithPath: a[2]), format: .RGBA8, colorSpace: CGColorSpace(name: CGColorSpace.sRGB)!)
    print("instances: \(r.allInstances.count), picked: \(label), size: \(Int(out.extent.width))x\(Int(out.extent.height))")
} catch { print("error: \(error)"); exit(3) }
