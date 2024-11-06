import SwiftUI

struct CrashReportView: View {
    let udid: String
    @State var log: String = ""
    @State var ran = false
    var body: some View {
        NavigationView {
            ScrollViewReader { proxy in
                ScrollView {
                    Text(log)
                        .font(.system(size: 12).monospaced())
                        .fixedSize(horizontal: false, vertical: false)
                        .textSelection(.enabled)
                    Spacer()
                        .id(0)
                }
                .onAppear {
                    guard !ran else { return }
                    ran = true
                    
                    logPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                        let data = fileHandle.availableData
                        if !data.isEmpty, var logString = String(data: data, encoding: .utf8) {
                            if logString.contains(udid) {
                                logString = logString.replacingOccurrences(of: udid, with: "<redacted>")
                            }
                            log.append(logString)
                            proxy.scrollTo(0)
                        }
                    }
                    
                    DispatchQueue.global(qos: .background).async {
                        performCrashReport()
                    }
                }
            }
        }
        .navigationTitle("Log output")
    }
    
    init() {
        setvbuf(stdout, nil, _IOLBF, 0) // make stdout line-buffered
        setvbuf(stderr, nil, _IONBF, 0) // make stderr unbuffered
        
        // create the pipe and redirect stdout and stderr
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stdout))
        dup2(logPipe.fileHandleForWriting.fileDescriptor, fileno(stderr))
        
        let deviceList = MobileDevice.deviceList()
        guard deviceList.count == 1 else {
            print("Invalid device count: \(deviceList.count)")
            udid = "invalid"
            return
        }
        udid = deviceList.first!
    }
    
    func performCrashReport() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documentsDirectory.appendingPathComponent(udid, conformingTo: .data)
        
        do {
            try? FileManager.default.removeItem(at: folder)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
            
            // Restore now
            var args = [
                "idevicecrashreport",
                "./", "-k",
                documentsDirectory.path(percentEncoded: false)
            ]
            print("Executing args: \(args)")
            var argv = args.map{ strdup($0) }
            let result = idevicecrashreport_main(Int32(args.count), &argv)
            print("idevicecrashreport exited with code \(result)")
            
            log.append("\n")
            if log.contains("Domain name cannot contain a slash") {
                log.append("Result: this iOS version is not supported.")
            } else if log.contains("crash_on_purpose") {
                log.append("Result: restore successful.")
            }
            
            logPipe.fileHandleForReading.readabilityHandler = nil
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    
}
