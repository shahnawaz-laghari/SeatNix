# SeatNix Appwrite setup

The Flutter app uses only the Appwrite endpoint and Project ID. Email/password
authentication is enabled. Never add an Appwrite server API key to the app, an
asset, or a checked-in configuration file.

## Register the mobile app

The Android platform is registered in Appwrite:

- Package name: `com.seatnix.app`

For Flutter Web email-verification links, make sure a **Web** platform is also
registered with hostname `localhost` (and the actual hostname if the web app is
deployed). The callback host is taken from the page where sign-up occurs, and
Appwrite only sends verification links to registered platform hosts.

## Backend resources

The Appwrite database and avatar bucket are provisioned for this project:

- Database ID: `seatnix`
- Trips table ID: `trips`
- Avatar bucket ID: `avatars`

The trips table has **Row security** enabled and its query index is available.
Its columns are:

| Column ID | Type | Required |
| --- | --- | --- |
| `userId` | String (36) | Yes |
| `reference` | String (24) | Yes |
| `from` | String (100) | Yes |
| `to` | String (100) | Yes |
| `seat` | String (8) | Yes |
| `travelDate` | Datetime | Yes |
| `total` | Integer | Yes |
| `paymentMethod` | String (32) | Yes |
| `paymentDetail` | String (64) | Yes |
| `paidAt` | Datetime | Yes |

The **Users** role can create rows at the table level. Row-level permissions
are assigned to each trip row so an account can only read, update, or delete
its own trips.

The `avatars` bucket is private and permits authenticated users to create files.
Each uploaded avatar file is accessible only to its owner. Profile name and
phone number use Appwrite Account and Account Preferences.

## Account transition

Supabase password hashes cannot be imported into Appwrite. Existing users need
to register with Appwrite again. Existing trip records in the old app are
device-local and tied to the old Supabase user ID; they are not automatically
associated with a new Appwrite account.
