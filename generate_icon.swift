import Cocoa

let size = CGSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let rect = NSRect(origin: .zero, size: size)
let path = NSBezierPath(roundedRect: rect, xRadius: 224, yRadius: 224)
NSColor.white.setFill()
path.fill()

let gradient = NSGradient(starting: NSColor(red: 0.1, green: 0.5, blue: 1.0, alpha: 1.0),
                          ending: NSColor(red: 0.0, green: 0.3, blue: 0.8, alpha: 1.0))!
gradient.draw(in: path, angle: -90)

if let symbol = NSImage(systemSymbolName: "calendar.badge.clock", accessibilityDescription: nil) {
    let symbolRect = NSRect(x: 150, y: 150, width: 724, height: 724)
    symbol.draw(in: symbolRect)
}

image.unlockFocus()

if let tiff = image.tiffRepresentation,
   let bitmap = NSBitmapImageRep(data: tiff),
   let png = bitmap.representation(using: .png, properties: [:]) {
    try? png.write(to: URL(fileURLWithPath: "icon_1024x1024.png"))
}
