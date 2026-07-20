import AVFoundation
import Foundation

struct AudioEnergyProfile: Sendable {
    let bucketDuration: Double
    let values: [Double]

    func energy(at time: Double) -> Double {
        guard time.isFinite, bucketDuration > 0, !values.isEmpty else { return 0 }
        let index = max(0, min(values.count - 1, Int(time / bucketDuration)))
        return values[index]
    }
}

enum AudioEnergyAnalyzer {
    static func analyze(url: URL, bucketDuration: Double = 0.055) -> AudioEnergyProfile? {
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let sampleRate = format.sampleRate
            let channelCount = Int(format.channelCount)
            guard sampleRate > 0, channelCount > 0 else { return nil }

            let framesPerBucket = max(1, Int(sampleRate * bucketDuration))
            let readCapacity: AVAudioFrameCount = 16_384
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: readCapacity) else { return nil }

            var buckets: [Double] = []
            var bucketSum = 0.0
            var bucketCount = 0
            var frameCursor = 0
            let sampleStride = max(1, Int(sampleRate / 260))

            while file.framePosition < file.length {
                try file.read(into: buffer, frameCount: readCapacity)
                let frameLength = Int(buffer.frameLength)
                guard frameLength > 0 else { break }

                if let channels = buffer.floatChannelData {
                    for frame in stride(from: 0, to: frameLength, by: sampleStride) {
                        var frameEnergy = 0.0
                        for channel in 0..<channelCount {
                            let sample = Double(channels[channel][frame])
                            frameEnergy += sample * sample
                        }
                        bucketSum += frameEnergy / Double(channelCount)
                        bucketCount += 1

                        let bucketBoundary = (frameCursor + frame) / framesPerBucket
                        let nextBoundary = (frameCursor + min(frame + sampleStride, frameLength)) / framesPerBucket
                        if nextBoundary > bucketBoundary {
                            buckets.append(bucketCount > 0 ? sqrt(bucketSum / Double(bucketCount)) : 0)
                            bucketSum = 0
                            bucketCount = 0
                        }
                    }
                }

                frameCursor += frameLength
            }

            if bucketCount > 0 {
                buckets.append(sqrt(bucketSum / Double(bucketCount)))
            }
            guard !buckets.isEmpty else { return nil }

            let normalized = normalize(buckets)
            return AudioEnergyProfile(bucketDuration: bucketDuration, values: normalized)
        } catch {
            return nil
        }
    }

    private static func normalize(_ values: [Double]) -> [Double] {
        let sorted = values.sorted()
        let floor = sorted[max(0, min(sorted.count - 1, Int(Double(sorted.count) * 0.15)))]
        let ceiling = sorted[max(0, min(sorted.count - 1, Int(Double(sorted.count) * 0.95)))]
        let span = max(ceiling - floor, 0.0001)

        var previous = 0.0
        return values.map { raw in
            let normalized = max(0, min(1, (raw - floor) / span))
            let emphasized = pow(normalized, 0.62)
            let smoothed = previous * 0.52 + emphasized * 0.48
            previous = smoothed
            return smoothed
        }
    }
}
