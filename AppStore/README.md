# Store resources

The first-release offer is free use on one device with optional paid
iCloud synchronization of the Stally library. The subscription does not add
iCloud storage capacity. Enabling or disabling synchronization takes effect on
the next launch, and ending a subscription does not delete local records.

## App description

`Metadata/en-US/description.txt` and `Metadata/ja/description.txt` are the
version-level descriptions for App Store Connect. `../apogee.json` resolves the
app by its bundle identifier. Use Apogee to validate, plan, apply and read back
these files. Keep the Store's app-info and version locale sets aligned.

Descriptions refer to the regional price shown before purchase instead of
embedding a single currency amount for every storefront. Subscription name,
description, period and pricing intent are recorded in `subscription.json`;
this file is a reference contract, not an Apogee input format.

Do not promote the absence of advertising in Store copy: advertising is planned
soon after the first release. Describe only the paid benefits currently supplied.

## Monthly subscription

- Product ID: `com.muhiro12.Stally.subscriptions.monthly`.
- Subscription period: `ONE_MONTH`.
- United States: USD 2.99 per month.
- Japan: JPY 300 per month, overriding Apple's equalized price.
- Other territories use Apple's equalized prices for the USD 2.99 price point.
  These are the prices selected at configuration time; subscriptions do not
  automatically follow later exchange-rate changes.
- App download price: free.
- Subscription availability includes all current territories and automatically
  includes new territories. App distribution requirements remain separate.
- The paid benefit is optional library synchronization through the customer's
  own iCloud account. Advertising removal is not a paid benefit.

The App Store Connect API payment plan is `UPFRONT`: the customer pays for each
one-month subscription period. It does not create an annual commitment.
The API's `MONTHLY` plan means monthly payments over a 12-month commitment and
is not this offer. See Apple's
[subscription pricing guidance](https://developer.apple.com/documentation/appstoreconnectapi/configuring-subscription-prices-across-territories).

Store configuration does not establish purchase/restore behavior, production
CloudKit synchronization, review approval or release readiness. Complete the
remaining checks in [distribution readiness](../docs/release-readiness.md).
