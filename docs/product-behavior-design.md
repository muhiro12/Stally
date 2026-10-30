# Product Behavior Design

## Status and Authority

On October 28, 2026, the owner clarified the next design phase: build the
product from the accepted foundational contracts, then design its capabilities
and behavior, Operations, and app/system adapters. Existing Operations and
temporary UI arrangements do not establish accepted product requirements.
Implementation may inform feasibility after the intended behavior is clear.

The [contract summary](first-release-contract-summary.md) and its linked
decisions remain authoritative for identity, recorded meaning, preservation,
ownership, and published boundaries. The explicitly accepted October 28
representative-link addition below extends that foundation; other proposals
do not change it.
The shared Operations architecture remains selected; its concrete use cases,
method signatures, and factoring remain design work.

Below, **contract consequence** means behavior already constrained by accepted
decisions. **Proposal** means a recommended product expression for discussion,
not owner approval, a frozen interface, or completed implementation. Existing
product records supply intent and examples, not an obligation to restore every
legacy feature. The database does not, by itself, decide which experiences are
valuable or how a person should use them.

## Product Center

Stally preserves a person's record of a subject and their relationship with it.
The subject may be a particular object, a continuing product, or a place; the
person decides what belongs to one Item. Photos and notes supply context,
Marks record occurrences, and periods retain relationship history.

Proposal: make these equally valid ways to begin, without requiring a mode
that permanently partitions Items:

- Keep something in mind through its name, notes, and photos.
- Record particular occasions on which it was chosen or used.
- Keep the periods during which it was part of the person's life.
- Combine these forms of knowledge when useful.

For example, a notebook may initially have only a photo and note. A favorite
cafe may accumulate visit Marks. A bicycle may have an ongoing period with
only its start year known. None requires invented occurrences or dates to
qualify as a useful record. These are usage examples, not built-in categories.

## Accepted Context and Favorite Decisions

On October 28, the owner accepted the following direction after discussing
dedicated attributes, free-form context, and the value of additional choices.
These decisions are selected product behavior, not completed implementation.

- An Item can have **one optional representative URL**, chosen by the person.
  Its purpose is a predictable, readily accessible action that opens the
  Item's chosen destination, such as a store, product page, or another app.
  It is separate from the link that opens this Item inside Stally.
- Follow the platform's URL-opening behavior. An appropriate URL can open a
  related app, but Stally does not guarantee that every destination has an
  installed handler or remains available.
- Do not infer the representative URL from the first URL in the note. Adding,
  replacing, or clearing the representative link changes only that reference;
  it does not rewrite the note or change Item identity and history.
- Do not introduce a URL array, named-link collection, ordering, or primary-link
  selection among several entries for this feature. Those would serve a
  different, currently unselected reference-management capability.
- Keep `isFavorite` as a Bool: an explicit choice to include the Item among
  favorites. It is not a graded rating, priority, or relative ranking. Do not
  replace it with an Int solely to reserve future values.
- Use notes for additional context whose structured use is not yet selected.
  Purchase dates, acquisition sources, gift givers, and rating levels do not
  gain dedicated fields from hypothetical demand alone. Reconsider a field
  when a concrete product behavior establishes its meaning and cardinality.

The representative URL is a new retained fact and must participate in storage,
sync, export/import, and applicable system access. Preserve existing notes and
allow older Items to have no representative link; do not automatically extract
one during migration. An older supported import without this field must not
erase an existing link. Finalize its physical representation, wire key, input
validation, and opening/failure presentation during implementation.

The implemented V3 schema does not contain this field. Preserve its historical
snapshot and qualify the successor schema and file version when integrating
the addition. This design decision neither changes a store nor promotes a
CloudKit schema.

## Capability and Behavior Map

### Keep a Subject and Its Context

Contract consequences:

- Creating an Item does not implicitly create a Mark or period.
- Changing its description preserves identity and existing history.
- Classification is optional, user-defined, and can include several Tags.
- The person can choose one representative link and open it directly, without
  searching the note. See the accepted October 28 decision above.
- Photos are independently retained attachments with captions and ordering;
  they are not references whose survival depends on the source photo library.
- Deleting an Item also deletes its owned Marks, periods, and photos. Shared
  Tags and unrelated Items survive.

Accepted product behavior on October 30:

- Create an Item with a nonblank name. Notes, photos, Tags, and the
  representative URL are optional; they can also be added or edited later.
- Permit distinct Items with the same name. Do not infer that the person
  intended to reuse, replace, or combine an existing Item.
- Edit name and note while preserving Item identity and unrelated information.
- Add multiple photos, edit their captions and order, and delete individual
  attachments without recreating the Item.
- Set, replace, clear, and open the one optional representative URL.
- Assign or remove existing Tags and allow explicit creation of a new Tag
  when needed. Same-name identity rules continue to apply.
- Confirm Item deletion with its owned Mark, period, and photo consequences.
  Shared Tags and unrelated records survive.

Treat the content submitted as one save action as a unit. If that submission
includes photos, a partial save must not be presented as full completion.
Cancellation leaves existing records unchanged. A save failure retains the
editing input for correction and retry; this does not establish a separate
promise of draft recovery after process termination. An edit preserves values
the person did not change rather than resetting omitted fields.

Item registration and the first Mark or period express separate intentions.
Registration does not imply purchase, use, or relationship start. A continuous
screen flow may offer explicit history entry, but must not create today's Mark
or begin a period merely because an Item was added. If a future flow submits
Item and explicit history together as one action, apply the same save-unit rule.

Screen composition, the initial visibility of optional inputs, and Operations
signatures remain implementation/design work. These accepted behaviors do not
freeze the current editor or its existing method calls.

### Record and Correct Occurrences

Contract consequences:

- Each Mark is one occurrence. Several Marks on the same day are valid.
- A Mark has a known day and optionally a known minute; absence of time does
  not mean midnight or the time the record was created.
- Backdating and correcting occurrence knowledge are supported. Correction
  keeps the Mark's identity and registration metadata.
- Increasing a day's count adds records; reducing it removes identified
  records. It does not overwrite a stored daily counter or discard arbitrary
  timed occurrences.
- Pausing new recording retains history and permits correction. Resuming
  recording does not add a Mark or change a relationship period.

Accepted product behavior on October 30:

- The common task adds one occurrence to an Item with a known day and
  optional minute knowledge.
- **Record today:** use today's date without an occurrence time. This is the
  default lightweight capture behavior, including when recording later in the
  day; entry time must not silently become occurrence time.
- **Record now:** explicitly record the current date and clock time to minute
  precision. This retains the selected civil-date/time meaning, not a stored
  time zone or an absolute occurrence instant.
- **Record a specified date/time:** use the selected day and an optional time,
  including for backdated entry.
- Each deliberate addition creates another occurrence, even if another Mark
  has the same day or minute. Do not infer identity from those values.
- Undo of the just-added occurrence targets that particular record, leaving
  other Marks intact. It must not resolve to whichever record is now latest
  after another entry or synchronization.
- Allow later date/time correction, adding a previously unknown time, and
  removing time knowledge while retaining the known day. These changes retain
  the same Mark identity and registration metadata.
- While new recording is paused, reject additions but retain access to
  correction and deletion of existing Marks.

The three capture meanings do not prescribe three always-visible buttons,
three Operations methods, or a particular App Intent inventory. Their surface
composition remains design work. Preserve a calm experience for someone who
records once a day; additional occurrences do not imply better participation.

Still to decide: the first-release interaction for day-count correction and
the presentation of date/time input and undo. A count editor must express the
accepted additions/removals, with clear selection when reducing a count would
remove distinguishable timed records. Handling accidental repeated activation
must not silently reinstate a one-per-day rule.

### Keep Relationship Periods

Contract consequences:

- Start and end knowledge may be unknown, a year, a month, or an exact day.
  Ongoing and ended-with-unknown-end remain different facts.
- Ending retains the period identity and start. Genuine resumption creates a
  new period; correcting an accidental end edits the original period.
- Periods belong to an Item; Marks do not belong to periods and need not be
  constrained to their boundaries.
- Ordinary local edits preserve the accepted single-ongoing and definite-
  overlap rules. Incoming conflicts remain inspectable rather than silently
  repaired. See [period rules](period-schema-validation.md).

Accepted product behavior on October 30:

- **Add a period:** allow both an ongoing relationship and a previously ended
  relationship to be recorded, using only the boundary precision known.
- **End a period:** mark that period as ended while preserving its start and
  identity. Its end may remain unknown; use today only when explicitly chosen,
  not merely because the end action was performed today.
- **Resume a relationship:** retain the ended period and create a new ongoing
  period. Do not erase the previous ending or the gap between periods.
- **Correct a period:** edit its start, end, or continuation state while
  retaining identity. Correcting a mistaken ending is different from recording
  a genuine later resumption; it does not create another period.
- **Delete a period:** remove only the selected period, preserving its Item,
  Marks, and other periods.

Year-only, month-only, and day knowledge are valid inputs. An ongoing period
may have an unknown start, and an ended period may have an unknown end.
Having no recorded period is different from explicitly recording an ongoing
period with an unknown start. Do not infer one from the other or from Item
registration, Mark additions, or Archive changes.

Establish these history operations before selecting elapsed/total readings.
Exact screen wording, entry controls, and calculation policies remain design
work. The existing period-readings proposal remains unaccepted; unknown
boundaries must not become exact totals.

### Organize and Find Records

Contract consequences:

- Archive changes everyday visibility; it does not end a period, remove
  history, or assert disposal. Favorites and Mark recording remain independent.
- Same-name Tags remain distinct identities. Renaming does not merge them.
- Explicit Tag consolidation has the accepted bounded reassignment/deletion
  meaning, including its limits on unseen remote assignments and old references.

Proposal:

- Help people find Items by remembered description and chosen Tags, and
  inspect related Items without imposing a fixed classification system.
- Provide deliberate access to archived records and useful favorite filtering.
  Filters should make their archive scope understandable.
- Support adding/removing classifications and an explicit reviewed way to
  consolidate Tags. Do not infer consolidation from spelling similarity.

To decide: search fields and matching, filter combinations, sorting, and bulk
actions. Independent stored state does not require a permanent switch for each
field, a dedicated screen for each state, or the current sidebar arrangement.

### Revisit and Understand the Record

Contract consequences:

- Occurrence count and number of days with occurrences are different readings.
- Registration time is not relationship start or occurrence time. Missing
  recordings are not proof that the subject was unused or unimportant.
- Readings must retain source precision and selected scope. Derived displays
  do not silently create new authoritative facts.

Proposal:

- Begin with understandable history for one Item: its recorded occurrences,
  periods, and visual context.
- Add collection readings only around a useful question, such as which Items
  have recorded activity in a chosen interval or what a chosen Tag contains.
- Consider gentle prompts to revisit records separately from factual history;
  a prompt expresses a suggestion, not a conclusion about the person's life.

To decide: which questions justify calculations or suggestions, their scope,
and their definitions. Legacy Review lanes, streaks, rankings, health scores,
and fixed 30/90/365-day windows are candidates to reassess, not a required
dashboard. This does not reject the value of reflection or decide its release
scope by omission.

### Use the Record Outside Stally and Bring It Back

Contract consequences:

- Ordinary export uses the selected `.stally` package, with or without images.
  Auxiliary JSON sharing supports external tools, including analysis.
- Import preserves identity, reviews differences, and does not infer local
  deletion from absence or erase photos because a file omits image bytes.
- Same identity and contents do not create another occurrence. Conflicting
  contents require an explicit choice; timestamps do not establish a winner.
- Whole-library replacement and Import as Copy are not selected for 1.0.

Proposal:

- Present export as taking the record elsewhere, with retaining a backup as
  one useful purpose. No AI tutorial or destructive restore center is required.
- Explain what is included before export and what would change before import.
- Restore into an empty collection through the same ordinary import behavior.

To decide: export/share entry points, review grouping, cancellation, and
concrete resource limits. Follow the existing file and import designs rather
than inheriting the old merge/replace/reset workflow.

## Consistent Behavior Across Entry Points

The chosen product capabilities will be represented by shared Operations.
Screens, App Intents, and future system surfaces adapt those capabilities;
they must not invent different meanings for the same task. A compound user
task may need a deliberate operation rather than a series of unrelated saves.

Native synchronization, shared storage, links, localization, and platform
integration support the experience. Their accepted scope remains in force,
but they do not supply the missing feature design. A local saved result must
not be described as proof that every device has received it.

For every proposed user action, establish these before naming methods or
Intent types:

1. The person's purpose and the facts they supply.
2. Omitted, unknown, and explicitly cleared values; any suggested defaults.
3. The facts changed and the facts preserved.
4. The result the person can observe or reuse.
5. Repeated execution, invalid input, cancellation, conflicts, and save failure.
6. Any consequential choice or confirmation required to perform that task.

App Intent identities, parameter representations, discovery, and system
authentication are then adapter/publication decisions. The feature inventory
must cover all selected application capabilities, including those whose
adapters should not be discoverable. This is not one Intent per helper method.

## Discussion Order

Proposal: begin with Item creation and description, then occurrence capture
and correction, period history, organization, readings, and external use.
Design complete user actions at each step; translate them into Operations and
adapters after agreement. Validate cross-cutting failure behavior as those
actions become concrete.

This order is a discussion plan, not a release cut or an instruction to finish
every screen before considering system use. Revisit existing implementation
only to identify what can serve the chosen behavior and what needs replacement.
