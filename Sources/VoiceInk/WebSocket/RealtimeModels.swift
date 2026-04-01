import Foundation

// MARK: - Client Events (Client → Server)

struct SessionUpdateEvent: Encodable {
    let type = "session.update"
    let session: SessionConfig
}

struct SessionConfig: Encodable {
    let modalities: [String]
    let instructions: String
    let input_audio_format: String
    let turn_detection: TurnDetectionConfig?

    init(modalities: [String], instructions: String, inputAudioFormat: String = "pcm", turnDetection: TurnDetectionConfig? = nil) {
        self.modalities = modalities
        self.instructions = instructions
        self.input_audio_format = inputAudioFormat
        self.turn_detection = turnDetection
    }
}

struct TurnDetectionConfig: Encodable {
    let type: String
    let threshold: Double?
    let silence_duration_ms: Int?

    static func serverVAD(threshold: Double = 0.5, silenceDurationMs: Int = 500) -> TurnDetectionConfig {
        TurnDetectionConfig(type: "server_vad", threshold: threshold, silence_duration_ms: silenceDurationMs)
    }
}

/// Represents JSON `null` — no longer used for turn_detection but kept for potential future use
struct JSONNull: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encodeNil()
    }
}

struct AudioAppendEvent: Encodable {
    let type = "input_audio_buffer.append"
    let audio: String
}

struct AudioCommitEvent: Encodable {
    let type = "input_audio_buffer.commit"
}

struct ResponseCreateEvent: Encodable {
    let type = "response.create"
}

struct ResponseCancelEvent: Encodable {
    let type = "response.cancel"
}

// MARK: - Server Events (Server → Client)

struct ServerEvent: Decodable {
    let type: String
    let delta: String?
    let text: String?
    let transcript: String?
    let error: ServerError?

    private enum CodingKeys: String, CodingKey {
        case type, delta, text, transcript, error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        delta = try container.decodeIfPresent(String.self, forKey: .delta)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        transcript = try container.decodeIfPresent(String.self, forKey: .transcript)
        error = try container.decodeIfPresent(ServerError.self, forKey: .error)
    }
}

struct ServerError: Decodable {
    let type: String?
    let code: String?
    let message: String?
}

// MARK: - Server Event Types

enum ServerEventType: String {
    case sessionCreated = "session.created"
    case sessionUpdated = "session.updated"
    case inputAudioBufferCommitted = "input_audio_buffer.committed"
    case responseCreated = "response.created"
    case responseTextDelta = "response.text.delta"
    case responseTextDone = "response.text.done"
    case responseAudioTranscriptDelta = "response.audio_transcript.delta"
    case responseAudioTranscriptDone = "response.audio_transcript.done"
    case responseDone = "response.done"
    case error = "error"
}

// MARK: - App Errors

enum VoiceInkError: LocalizedError {
    case missingAPIKey
    case connectionFailed(String)
    case timeout
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API Key is not configured. Please set it in Settings."
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .timeout:
            return "Request timed out."
        case .apiError(let msg):
            return "API error: \(msg)"
        }
    }
}
