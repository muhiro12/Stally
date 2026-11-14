# App Intents Direction and Contract Boundary

The [publication inventory](app-intents-publication-review.md) specifies the
first-release actions, parameter defaults, results and protected writes.
Start changes from the [product behavior](product-behavior-design.md) and the
shared Operations called by each adapter.

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
purpose. The publication inventory records the policy for each implemented action.

App Shortcuts, invocation phrases, preconfigured entrypoints, and composed
workflows are delivery and experience design. They remain deferred, including
potential delivery after 1.0. No promoted phrases are defined for 1.0.

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

Expose record facts through entity properties and compose display text
separately. Temporal precision, unknown values, and ongoing state must be usable
without parsing a subtitle. The publication inventory lists the selected fields.

Decide retrieval and sorting needs at the Operations/query boundary first.
Adapters reuse that behavior. An array result alone is not a reason to invent
sorting options; existing app behavior supplies the item-scoped collection
orders recorded in the publication inventory.

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

## Apple References

- [AppIntent](https://developer.apple.com/documentation/appintents/appintent).
- [Discovery](https://developer.apple.com/documentation/appintents/appintent/isdiscoverable).
- [Authentication policy](https://developer.apple.com/documentation/appintents/appintent/authenticationpolicy).
- [Cross-device authentication](https://developer.apple.com/documentation/appintents/intentauthenticationpolicy/requiresauthentication).
- [App Shortcuts](https://developer.apple.com/documentation/appintents/appshortcut).
