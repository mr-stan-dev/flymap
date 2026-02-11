import Foundation
import FMDB

class MBTilesURLProtocol: URLProtocol {
    
    // Supported scheme
    static let scheme = "mbtiles"
    
    override class func canInit(with request: URLRequest) -> Bool {
        guard let url = request.url else { return false }
        return url.scheme == MBTilesURLProtocol.scheme
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MBTilesURLProtocol", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        // Handle TileJSON request (metadata)
        // URL format: mbtiles:///path/to/file.mbtiles
        // Or if it's the root request for source
        if url.pathExtension == "mbtiles" {
            handleTileJSONRequest(url: url)
            return
        }

        // Handle Tile request
        // URL format: mbtiles:///path/to/file.mbtiles/z/x/y.pbf
        // We need to parse this carefully
        if let (filePath, z, x, y) = parseTileURL(url) {
            handleTileRequest(filePath: filePath, z: z, x: x, y: y)
        } else {
             client?.urlProtocol(self, didFailWithError: NSError(domain: "MBTilesURLProtocol", code: 404, userInfo: [NSLocalizedDescriptionKey: "Malformed Tile URL"]))
        }
    }
    
    override func stopLoading() {
        // Cleaning up not required for sync DB access
    }
    
    // MARK: - Handlers
    
    private func handleTileJSONRequest(url: URL) {
        // Generate TileJSON that points back to this protocol for tiles
        // The URL is the absolute path to the mbtiles file
        let path = url.path
        
        let tileJSON: [String: Any] = [
            "tilejson": "2.0.0",
            "name": "Offline Map",
            "format": "pbf",
            "tiles": [
                "mbtiles://\(path)/{z}/{x}/{y}.pbf"
            ],
            "minzoom": 0,
            "maxzoom": 14
        ]
        
        do {
            let data = try JSONSerialization.data(withJSONObject: tileJSON, options: [])
            sendResponse(data: data, mimeType: "application/json")
        } catch {
             client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    private func handleTileRequest(filePath: String, z: Int, x: Int, y: Int) {
        // Standard MBTiles uses TMS (flipped Y)
        // MapLibre requests XYZ
        // We need to flip Y: y_tms = (1 << z) - 1 - y_xyz
        let yTms = (1 << z) - 1 - y
        
        if !FileManager.default.fileExists(atPath: filePath) {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MBTilesURLProtocol", code: 404, userInfo: [NSLocalizedDescriptionKey: "MBTiles file not found at \(filePath)"]))
            return
        }
        
        let db = FMDatabase(path: filePath)
        guard db.open() else {
            client?.urlProtocol(self, didFailWithError: NSError(domain: "MBTilesURLProtocol", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to open database"]))
            return
        }
        
        defer {
            db.close()
        }
        
        do {
            // Try to query the tile
            let resultSet = try db.executeQuery("SELECT tile_data FROM tiles WHERE zoom_level=? AND tile_column=? AND tile_row=?", values: [z, x, yTms])
            
            if resultSet.next() {
                if let data = resultSet.data(forColumn: "tile_data") {
                    sendResponse(data: data, mimeType: "application/x-protobuf")
                } else {
                    // Empty tile
                    sendResponse(data: Data(), mimeType: "application/x-protobuf")
                }
            } else {
                // Not found - MapLibre handles 404 cleanly (just empty space)
                // But better to return empty response to avoid logs spam
                client?.urlProtocol(self, didFailWithError: NSError(domain: "MBTilesURLProtocol", code: 404, userInfo: [NSLocalizedDescriptionKey: "Tile not found"]))
            }
            resultSet.close()
        } catch {
             client?.urlProtocol(self, didFailWithError: error)
        }
    }
    

    
    // MARK: - Helpers
    
    private func sendResponse(data: Data, mimeType: String) {
        var headers = ["Content-Type": mimeType, "Content-Length": String(data.count)]
        if isGzipped(data) {
            headers["Content-Encoding"] = "gzip"
        }
        
        if let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "1.1", headerFields: headers) {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } else {
            // Fallback
             let response = URLResponse(url: request.url!, mimeType: mimeType, expectedContentLength: data.count, textEncodingName: nil)
             client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
             client?.urlProtocol(self, didLoad: data)
             client?.urlProtocolDidFinishLoading(self)
        }
    }
    
    private func isGzipped(_ data: Data) -> Bool {
        return data.count >= 2 && data[0] == 0x1f && data[1] == 0x8b
    }
    
    private func parseTileURL(_ url: URL) -> (String, Int, Int, Int)? {
        // Expected: mbtiles:///absolute/path/to.mbtiles/z/x/y.pbf
        
        // Split by ".mbtiles"
        // components: ["mbtiles:///path/to", "/2/3/4.pbf"]
        // The path part might contain dots, so we search from end or handle carefully.
        
        let urlString = url.absoluteString
        // Scheme prefix
        guard let range = urlString.range(of: ".mbtiles") else { return nil }
        
        // File path is everything up to .mbtiles inclusive, but removing scheme
        // Actually, URL might be: mbtiles:///var/mobile/.../map.mbtiles/5/10/20.pbf
        
        let schemeHeader = "mbtiles://"
        guard urlString.hasPrefix(schemeHeader) else { return nil }
        
        let pathAndQuery = String(urlString.dropFirst(schemeHeader.count))
        
        // Find .mbtiles extension position
        guard let extensionRange = pathAndQuery.range(of: ".mbtiles") else { return nil }
        let endOfFilePathIndex = extensionRange.upperBound
        
        // Extract file path
        let filePath = String(pathAndQuery[..<endOfFilePathIndex])
        
        // Extract rest "/z/x/y.pbf"
        let rest = String(pathAndQuery[endOfFilePathIndex...])
        // If query part is empty (e.g. valid mbtiles metadata req), parsing tile fails (correctly)
        
        let components = rest.split(separator: "/")
        
        // Expected components: ["z", "x", "y.pbf"]
        if components.count == 3,
           let z = Int(components[0]),
           let x = Int(components[1]) {
            
            let yPart = components[2]
            // remove .pbf extension
            let yString = yPart.components(separatedBy: ".").first ?? String(yPart)
            if let y = Int(yString) {
                return (filePath, z, x, y)
            }
        }
        
        return nil
    }
}
