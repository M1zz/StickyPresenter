import AVFoundation
import CoreMediaIO
// usage: rec <out.mov>  — iPhone(USB) 화면을 H.264 로 기록. SIGINT/SIGTERM 으로 멈춘다.
var prop = CMIOObjectPropertyAddress(mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyAllowScreenCaptureDevices), mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal), mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))
var allow: UInt32 = 1
CMIOObjectSetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &prop, 0, nil, UInt32(MemoryLayout<UInt32>.size), &allow)
var dev: AVCaptureDevice?
for _ in 0..<30 {
  dev = AVCaptureDevice.DiscoverySession(deviceTypes: [.external], mediaType: nil, position: .unspecified).devices.first { $0.hasMediaType(.muxed) }
  if dev != nil { break }
  RunLoop.current.run(until: Date().addingTimeInterval(1))
}
guard let dev else { print("no device"); exit(1) }
let url = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.removeItem(at: url)
final class W: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
  var writer: AVAssetWriter?; var input: AVAssetWriterInput?; var stopping = false; var frames = 0
  let url: URL; init(url: URL) { self.url = url }
  func captureOutput(_ o: AVCaptureOutput, didOutput sb: CMSampleBuffer, from c: AVCaptureConnection) {
    if stopping { return }
    let t = CMSampleBufferGetPresentationTimeStamp(sb)
    if writer == nil {
      guard let fd = CMSampleBufferGetFormatDescription(sb) else { return }
      let dim = CMVideoFormatDescriptionGetDimensions(fd)
      let w = try! AVAssetWriter(outputURL: url, fileType: .mov)
      let i = AVAssetWriterInput(mediaType: .video, outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: dim.width, AVVideoHeightKey: dim.height])
      i.expectsMediaDataInRealTime = true
      w.add(i); w.startWriting(); w.startSession(atSourceTime: t)
      writer = w; input = i; print("started \(dim.width)x\(dim.height)"); fflush(stdout)
    }
    if input!.isReadyForMoreMediaData { input!.append(sb); frames += 1 }
  }
  func stop() {
    stopping = true
    guard let w = writer else { print("no frames"); exit(1) }
    input!.markAsFinished()
    w.finishWriting { print("saved frames=\(self.frames) status=\(w.status.rawValue) \(w.error?.localizedDescription ?? "")"); exit(0) }
  }
}
let s = AVCaptureSession()
s.addInput(try! AVCaptureDeviceInput(device: dev))
let out = AVCaptureVideoDataOutput()
let w = W(url: url)
let q = DispatchQueue(label: "rec")
out.setSampleBufferDelegate(w, queue: q)
s.addOutput(out)
s.startRunning()
print("recording"); fflush(stdout)
var srcs: [DispatchSourceSignal] = []
for sig in [SIGINT, SIGTERM] {
  signal(sig, SIG_IGN)
  let src = DispatchSource.makeSignalSource(signal: sig, queue: .main)
  src.setEventHandler { q.async { w.stop() } }
  src.resume(); srcs.append(src)
}
RunLoop.main.run()
