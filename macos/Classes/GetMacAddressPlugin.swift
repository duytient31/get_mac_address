import Cocoa
import FlutterMacOS

public class GetMacAddressPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "get_mac_address", binaryMessenger: registrar.messenger)
    let instance = GetMacAddressPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getMacAddress":
    guard let macAddress = getMacAddress() else {
        result(FlutterError.init(code: "load failure", message: "macOS mac address load failure",details: nil))
        return
    }
    result(macAddress)
    default:
      result(FlutterMethodNotImplemented)
    }
  }


  func FindEthernetInterfaces() -> io_iterator_t? {

      let matchingDictUM = IOServiceMatching("IOEthernetInterface");
      // Note that another option here would be:
      // matchingDict = IOBSDMatching("en0");
      // but en0: isn't necessarily the primary interface, especially on systems with multiple Ethernet ports.

      if matchingDictUM == nil {
          return nil
      }

      let matchingDict = matchingDictUM! as NSMutableDictionary
      matchingDict["IOPropertyMatch"] = [ "IOPrimaryInterface" : true]

      var matchingServices : io_iterator_t = 0
      if IOServiceGetMatchingServices(kIOMasterPortDefault, matchingDict, &matchingServices) != KERN_SUCCESS {
          return nil
      }

      return matchingServices
  }

  // Given an iterator across a set of Ethernet interfaces, return the MAC address of the last one.
  // If no interfaces are found the MAC address is set to an empty string.
  // In this sample the iterator should contain just the primary interface.
  func GetMACAddress(_ intfIterator : io_iterator_t) -> [UInt8]? {

      var macAddress : [UInt8]?

      var intfService = IOIteratorNext(intfIterator)
      while intfService != 0 {

          var controllerService : io_object_t = 0
          if IORegistryEntryGetParentEntry(intfService, kIOServicePlane, &controllerService) == KERN_SUCCESS {

              let dataUM = IORegistryEntryCreateCFProperty(controllerService, "IOMACAddress" as CFString, kCFAllocatorDefault, 0)
              if dataUM != nil {
                  let data = (dataUM!.takeRetainedValue() as! CFData) as Data
                  macAddress = [0, 0, 0, 0, 0, 0]
                  data.copyBytes(to: &macAddress!, count: macAddress!.count)
              }
              IOObjectRelease(controllerService)
          }

          IOObjectRelease(intfService)
          intfService = IOIteratorNext(intfIterator)
      }

      return macAddress
  }


  func getMacAddress() -> String? {
    var macAddresses: [String] = []

      if let intfIterator = FindEthernetInterfaces() {
          if let macAddress = GetMACAddress(intfIterator) {
             let macAddressString =  macAddressAsString = macAddress.map( { String(format:"%02x", $0) } ).joined(separator: ":")
              print(macAddressAsString!)

                    print(macAddressString)
            macAddresses.append(macAddressString)
          }

          IOObjectRelease(intfIterator)
      }
  return macAddresses.joined(separator: ";")
  }


}
