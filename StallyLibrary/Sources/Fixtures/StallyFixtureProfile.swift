#if DEBUG
/// Development profiles share the current domain without entering Release builds.
public enum StallyFixtureProfile: String, CaseIterable, Sendable {
    case empty
    case typical
    case dense
    case integration
    case timeTogether
    case history
    case stress
}
#endif
