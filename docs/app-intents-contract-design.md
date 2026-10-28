# App Intents Direction and Contract Boundary

## Status

On October 27, 2026, the owner clarified the direction below. It supersedes the
assistant's earlier proposal to restrict the first-release intent surface to a
small subset of actions. This is a design record, not an implementation change
or evidence of installed Shortcuts behavior.

The [five-model design](model-schema-design.md) defines the selected domain
facts. The [system interface document](system-interface-contract.md) records
the older implementation and its historical verification.

On October 28, the owner clarified that existing Operations are not a finalized
product interface. Begin with [product capabilities and behavior](product-behavior-design.md)
under the accepted foundational contracts, then shape Operations and their
Intent adapters. Do not treat this document as a request to freeze current
methods or decide product behavior through Intent parameters alone.

## Accepted Direction

Represent all application capabilities with App Intents that invoke the shared
Operations boundary. App UI and system interfaces should use the same use cases
rather than duplicate business rules. This is coverage of application features,
not a requirement to expose every internal helper as a separate intent or make
the UI call an intent instead of Operations.

Prepare an intent even for a capability that must not be externally exposed,
and configure it as undiscoverable. Do not exclude periods, tags, media,
import/export, or derived readings simply to reduce the compatibility surface.
Their concrete actions follow their feature design and Operations semantics.
This direction does not invent features that the app does not otherwise offer.

Decide authentication separately from discovery. Where Stally's needs are
already clear with high confidence, require authentication from the first
release. Do not mechanically inherit another app's provisional permissive
policy, or require authentication for every operation without considering its
purpose. Concrete per-action policies remain to be assessed during design and
implementation.

App Shortcuts, invocation phrases, preconfigured entrypoints, and composed
workflows are delivery and experience design. They remain deferred, including
potential delivery after 1.0. The earlier recommendation for five App Shortcuts
is withdrawn; no count or phrase set is selected here.

## What Is a Contract

An Operations method is not automatically a durable external contract simply
because an app screen or intent calls it. App-local call sites and internals can
usually evolve together. Shared-package consumers, persisted effects, and
external callers can create separate obligations that must be identified.

An App Intent is an interface, but a published interface can become a contract
when a user's saved workflow continues to depend on it:

| Decision | When it needs to be fixed or reviewed |
| --- | --- |
| Operations structure, method factoring, adapter composition | During implementation; not a session-completion prerequisite by itself |
| Intent type/parameter identities, entity IDs, enum raw values | Before external publication, with compatibility review for later changes |
| Input meanings/defaults, output types/units/precision, side effects | Before external publication because saved workflows depend on their meaning |
| Discovery, authentication, confirmation, foreground requirements | Before publication for each capability; later changes can affect existing automation |
| App Shortcut selection, suggested phrases, presentation | During experience design; invocation phrases acquire their own obligations once shipped |

For example, one execution adding a Mark versus ensuring one Mark exists for a
whole day produces different recorded facts. That behavior must be defined
before publishing the action. By contrast, splitting an internal Operations
method does not by itself require saved-shortcut compatibility work.

Similarly, a duration returned to another action needs a defined meaning and
unit before it is published. This does not require excluding a time-reading
intent from the architecture or settling all its details in this session.

## Native Controls and Their Limits

- Use `isDiscoverable` for system discovery. Apple documents that false still
  allows execution from the app interface or a widget; it is not a substitute
  for authentication, authorization, or domain validation.
- Use `authenticationPolicy` for system-enforced authentication. The default is
  `alwaysAllowed`. `requiresAuthentication` can be satisfied by an unlocked
  originating device; `requiresLocalDeviceAuthentication` requires unlocking
  the device executing the intent. Requiring authentication does not necessarily
  mean presenting a fresh biometric prompt on every invocation.
- Keep confirmation of a destructive or consequential action distinct from
  authentication. Authentication establishes the system's execution condition;
  confirmation asks whether the user intends this particular action.
- App Shortcuts preconfigure and promote an intent with invocation phrases and
  presentation metadata. A multi-action workflow composed in Shortcuts is a
  separate concept. Deferring app-provided App Shortcuts does not make
  discoverable App Intents unavailable in the Shortcuts action library.

Operations must retain the app's domain validation regardless of entrypoint.
For a truly prohibited external action, do not treat a presentation flag as the
only execution guard. Internal support/repair code is not automatically a
user-facing app capability that needs discoverable automation.

## Deferred Work and Session Exit

Do not freeze the previous proposal's exact action inventory, Swift type or
parameter names, entity property set, date parameter representation, deletion
confirmation policy, or automation exclusions. Those were assistant proposals,
not accepted decisions. Existing accepted model and data-preservation semantics
continue to apply when these interfaces are implemented.

During feature implementation, maintain coverage from application capability to
Operations, Intent adapter, discovery, and authentication/confirmation policy.
Before first publication, review extracted identities, inputs, results, side
effects, and saved-workflow behavior. Use repository build/library checks and
appropriate manual system-surface verification; a design document is not proof
of metadata extraction, Siri, locked-device, or installed Shortcuts behavior.

For this contract-design session, the architectural direction and publication
boundary are sufficient. Completing the feature inventory, designing adapters,
and selecting promoted shortcuts belong to the implementation/experience phase.
They remain pre-publication work where applicable, not reasons to prolong this
session or to omit functionality from the intent architecture.

## Apple References

- [AppIntent](https://developer.apple.com/documentation/appintents/appintent).
- [Discovery](https://developer.apple.com/documentation/appintents/appintent/isdiscoverable).
- [Authentication policy](https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy).
- [Cross-device authentication](https://developer.apple.com/documentation/appintents/intentauthenticationpolicy/requiresauthentication).
- [App Shortcuts](https://developer.apple.com/documentation/appintents/appshortcut).
