import Foundation

public enum PlayerError: Error, Equatable, Sendable {
    /// There is no player for this provider yet.
    case unsupportedProvider(MusicProvider)
    /// The user has not given the app access to the music service.
    case notAuthorized
    /// The account cannot play the song, e.g. Apple Music without an active subscription.
    case subscriptionRequired
    /// No song has the requested identifier.
    case songNotFound
    /// The player could not start or the music service returned an error.
    case unavailable
}

/// State of the player of a music service.
public enum PlaybackStatus: Equatable, Sendable {
    case stopped
    case playing
    case paused
}

/// Public data the Player repository returns once a song starts playing.
public protocol PlayerResponseProtocol: Sendable {
    /// Music service that plays the song.
    var provider: MusicProvider { get }
    /// Identifier of the song that is playing.
    var songID: String { get }
    /// Length of the song as the player knows it, when it knows it.
    var duration: TimeInterval? { get }
}
