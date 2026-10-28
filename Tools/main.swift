import Foundation

// Step 1 test tool: `ddc-test` reads brightness, `ddc-test 40` sets it.
let displays = DDCDisplay.externalDisplays()
print("external AV services found: \(displays.count)")

guard let display = displays.first(where: { $0.read(DDCDisplay.brightness) != nil }) else {
    print("no display answered DDC brightness read")
    exit(1)
}

let (current, max) = display.read(DDCDisplay.brightness)!
print("brightness: \(current) / \(max)")

if CommandLine.arguments.count > 1, let target = Int(CommandLine.arguments[1]) {
    let value = min(Swift.max(target, 0), max)
    print(display.write(DDCDisplay.brightness, value) ? "set to \(value)" : "write failed")
    if let after = display.read(DDCDisplay.brightness) { print("read back: \(after.current)") }
}
