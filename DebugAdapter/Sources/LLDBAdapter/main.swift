import Darwin
import Dispatch

func main() {
    signal(SIGINT) { sig in
        Adapter.shared.cancel(error: nil)
    }
    signal(SIGTERM) { sig in
        Adapter.shared.cancel(error: nil)
    }
    
    Adapter.shared.resume()
    
    dispatchMain()
}
