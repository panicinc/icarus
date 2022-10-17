import Darwin

signal(SIGINT) { sig in
    Adapter.shared.cancel(error: nil)
}
signal(SIGTERM) { sig in
    Adapter.shared.cancel(error: nil)
}

Adapter.shared.resume()
