# Swift DMS — iOS release artifacts

This is the **public release-only repo** for the [Swift DMS](https://swiftdms.ca) native iOS app. The source code lives in a separate private repo; this repo exists solely to host the `.ipa` artifact and the SideStore source manifest at publicly fetchable URLs so SideStore can install + auto-update the app.

## Install on iPhone (one-time setup)

1. Install **SideStore** on your iPhone: https://sidestore.io
2. Sign in to SideStore with a personal Apple ID (SideStore -> Settings -> Accounts)
3. In SideStore tap the **Sources** tab -> tap **+** -> paste:

   ```
   https://github.com/themrmana/swiftdms-releases/releases/download/latest-ios/sidestore-source.json
   ```

4. Tap **Browse** -> **Swift DMS** -> **GET** -- installs in ~30 sec
5. Tap the Swift DMS icon on your home screen

## Updates

Every successful main-branch iOS build auto-publishes a new release here. SideStore polls the source URL periodically (or pull-to-refresh in Browse tab) and shows an **UPDATE** button when a new build is available. Tap -> updates in ~30 sec.

## 7-day re-sign cycle

SideStore-installed apps need to be re-signed every 7 days (Apple's free-tier limit). SideStore does this automatically over Wi-Fi as long as you open it occasionally -- you'll typically never notice it.

## Manual install

If you prefer to skip the SideStore source flow, you can download the `.ipa` from the [latest release](https://github.com/themrmana/swiftdms-releases/releases/tag/latest-ios) and open it in SideStore via Files -> Share -> SideStore.
