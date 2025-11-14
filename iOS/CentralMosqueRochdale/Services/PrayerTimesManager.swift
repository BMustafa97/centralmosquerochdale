import Foundation

/// Manages prayer times data, handling S3 downloads, local caching, and fallback to bundled JSON
class PrayerTimesManager {
    static let shared = PrayerTimesManager()
    
    // S3 URL for prayer times
    private let s3URL = "https://central-mosque-prayer-times.s3.eu-west-1.amazonaws.com/PrayerTimes2025.json"
    
    // Cache file location in Documents directory
    private var cachedFileURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("PrayerTimes2025_cached.json")
    }
    
    // Bundled JSON fallback
    private var bundledFileURL: URL? {
        Bundle.main.url(forResource: "PrayerTimes2025", withExtension: "json")
    }
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Loads prayer times data with the following priority:
    /// 1. Try cached file from Documents directory
    /// 2. Try downloading from S3 (and cache it)
    /// 3. Fallback to bundled JSON file
    func loadPrayerTimes(completion: @escaping (Result<YearlyPrayerTimes, Error>) -> Void) {
        // First, try to load from cache
        if let cachedData = loadFromCache() {
            completion(.success(cachedData))
            
            // Silently update cache in background
            downloadFromS3InBackground()
            return
        }
        
        // If no cache, download from S3
        downloadFromS3 { [weak self] result in
            switch result {
            case .success(let data):
                completion(.success(data))
            case .failure(let error):
                print("Failed to download from S3: \(error.localizedDescription)")
                // Fallback to bundled JSON
                if let bundledData = self?.loadFromBundle() {
                    completion(.success(bundledData))
                } else {
                    completion(.failure(PrayerTimesError.noDataAvailable))
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Load from cached file in Documents directory
    private func loadFromCache() -> YearlyPrayerTimes? {
        guard FileManager.default.fileExists(atPath: cachedFileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: cachedFileURL)
            let decoder = JSONDecoder()
            let prayerTimes = try decoder.decode(YearlyPrayerTimes.self, from: data)
            print("✅ Loaded prayer times from cache")
            return prayerTimes
        } catch {
            print("❌ Error loading cached prayer times: \(error.localizedDescription)")
            // Remove corrupted cache file
            try? FileManager.default.removeItem(at: cachedFileURL)
            return nil
        }
    }
    
    /// Load from bundled JSON file
    private func loadFromBundle() -> YearlyPrayerTimes? {
        guard let bundleURL = bundledFileURL else {
            print("❌ Bundled prayer times file not found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: bundleURL)
            let decoder = JSONDecoder()
            let prayerTimes = try decoder.decode(YearlyPrayerTimes.self, from: data)
            print("✅ Loaded prayer times from bundle")
            return prayerTimes
        } catch {
            print("❌ Error loading bundled prayer times: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Download from S3 bucket
    private func downloadFromS3(completion: @escaping (Result<YearlyPrayerTimes, Error>) -> Void) {
        guard let url = URL(string: s3URL) else {
            completion(.failure(PrayerTimesError.invalidURL))
            return
        }
        
        print("⬇️ Downloading prayer times from S3...")
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(PrayerTimesError.invalidResponse))
                return
            }
            
            guard let data = data else {
                completion(.failure(PrayerTimesError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                let prayerTimes = try decoder.decode(YearlyPrayerTimes.self, from: data)
                
                // Save to cache
                self?.saveToCache(data)
                
                print("✅ Successfully downloaded and cached prayer times from S3")
                completion(.success(prayerTimes))
            } catch {
                completion(.failure(error))
            }
        }
        
        task.resume()
    }
    
    /// Download from S3 in background (for cache updates)
    private func downloadFromS3InBackground() {
        guard let url = URL(string: s3URL) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  error == nil else {
                print("⚠️ Background S3 update failed")
                return
            }
            
            // Validate JSON before saving
            do {
                _ = try JSONDecoder().decode(YearlyPrayerTimes.self, from: data)
                self?.saveToCache(data)
                print("✅ Background cache update successful")
            } catch {
                print("⚠️ Background S3 data validation failed: \(error.localizedDescription)")
            }
        }
        
        task.resume()
    }
    
    /// Save downloaded data to cache
    private func saveToCache(_ data: Data) {
        do {
            try data.write(to: cachedFileURL, options: .atomic)
            print("💾 Prayer times cached to: \(cachedFileURL.path)")
        } catch {
            print("❌ Error saving to cache: \(error.localizedDescription)")
        }
    }
    
    /// Clear cached prayer times
    func clearCache() {
        try? FileManager.default.removeItem(at: cachedFileURL)
        print("🗑️ Prayer times cache cleared")
    }
}

// MARK: - Error Types

enum PrayerTimesError: LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    case noDataAvailable
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid S3 URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received from server"
        case .noDataAvailable:
            return "No prayer times data available"
        }
    }
}
