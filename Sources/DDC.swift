import Foundation
import IOKit

/// DDC/CI over the external display's IOAVService (Apple Silicon).
final class DDCDisplay {
    static let brightness: UInt8 = 0x10

    private let service: IOAVService

    init(service: IOAVService) {
        self.service = service
    }

    /// All external AV services; the caller probes which one answers.
    static func externalDisplays() -> [DDCDisplay] {
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("DCPAVServiceProxy"), &iterator) == KERN_SUCCESS else {
            return []
        }
        defer { IOObjectRelease(iterator) }

        var displays: [DDCDisplay] = []
        while case let entry = IOIteratorNext(iterator), entry != 0 {
            defer { IOObjectRelease(entry) }
            let location = IORegistryEntryCreateCFProperty(entry, "Location" as CFString, kCFAllocatorDefault, 0)?
                .takeRetainedValue() as? String
            guard location == "External", let av = IOAVServiceCreateWithService(kCFAllocatorDefault, entry) else { continue }
            displays.append(DDCDisplay(service: av))
        }
        return displays
    }

    /// Returns (current, max) for a VCP code, or nil if the display didn't answer.
    func read(_ vcp: UInt8) -> (current: Int, max: Int)? {
        // Some displays want 0x51 in the request checksum, some don't; try both.
        for seed: UInt8 in [0x6E, 0x6E ^ 0x51] {
            var request: [UInt8] = [0x82, 0x01, vcp, 0]
            request[3] = request.dropLast().reduce(seed, ^)

            for _ in 0..<3 {
                usleep(10_000)
                guard IOAVServiceWriteI2C(service, 0x37, 0x51, &request, UInt32(request.count)) == kIOReturnSuccess else { continue }
                usleep(50_000)
                var reply = [UInt8](repeating: 0, count: 11)
                guard IOAVServiceReadI2C(service, 0x37, 0x51, &reply, UInt32(reply.count)) == kIOReturnSuccess else { continue }
                // reply: 6E 88 02 result vcp type maxH maxL curH curL chk
                let valid = reply[0..<10].reduce(UInt8(0x50), ^) == reply[10]
                if valid, reply[2] == 0x02, reply[3] == 0x00, reply[4] == vcp {
                    return (Int(reply[8]) << 8 | Int(reply[9]), Int(reply[6]) << 8 | Int(reply[7]))
                }
            }
        }
        return nil
    }

    @discardableResult
    func write(_ vcp: UInt8, _ value: Int) -> Bool {
        var packet: [UInt8] = [0x84, 0x03, vcp, UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF), 0]
        packet[5] = packet.dropLast().reduce(UInt8(0x6E ^ 0x51), ^)

        var ok = false
        for _ in 0..<2 {
            usleep(10_000)
            if IOAVServiceWriteI2C(service, 0x37, 0x51, &packet, UInt32(packet.count)) == kIOReturnSuccess { ok = true }
        }
        return ok
    }
}
