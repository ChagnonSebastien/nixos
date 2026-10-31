{ lib, ...}:

let
  # Lists fed to pi-hole as file:// adlists.
  # Attribute name becomes the file path: <name> -> ~/.config/pihole-lists/<name>.txt
  # Deny lists register with adlist type 0, allow/ lists with type 1 (antigravity).
  lists = {

    general = ''
      # General deny list (assign to Default group)
      # Format: plain domains (exact) and ABP ||domain^ (domain + subdomains, Pi-hole v6+)
      # Per-device exceptions live in allow/
      # Last updated: 2026-10-31

      # Google APIs (core; re-allowed per device in allow/)
      www.googleapis.com

      # Google account, payments, sharing
      people-pa.googleapis.com
      androidpay-users-pa.googleapis.com
      nearbysharing-pa.googleapis.com
      playatoms-pa.googleapis.com
      chat.google.com

      # Chrome / account sync plumbing
      chromesyncentities-pa.googleapis.com
      chromesyncpasswords-pa.googleapis.com
      securitydomain-pa.googleapis.com

      # Push notifications, device config, Chromium field trials
      notifications-pa.googleapis.com
      voledevice-pa.googleapis.com
      clientservices.googleapis.com

      # Firebase remote config (feature flags)
      firebaseremoteconfig.googleapis.com
      firebaseremoteconfigrealtime.googleapis.com

      # Firebase Cloud Messaging (push notifications)
      mtalk.google.com
      alt1-mtalk.google.com
      alt2-mtalk.google.com
      alt3-mtalk.google.com
      alt4-mtalk.google.com
      alt5-mtalk.google.com
      alt6-mtalk.google.com
      alt7-mtalk.google.com
      alt8-mtalk.google.com

      # Google Assistant, voice, Home integration, Google TV home
      embeddedassistant.googleapis.com
      speechs3proto2-pa.googleapis.com
      googlehomefoyer-pa.googleapis.com
      calendarpushsubscription-pa.googleapis.com
      feedback-pa.googleapis.com
      playmoviesdfe-pa.googleapis.com
      youtubei.googleapis.com
      i.ytimg.com

      # Google TV home screen recommendation artwork
      encrypted-tbn0.gstatic.com
      encrypted-tbn1.gstatic.com
      encrypted-tbn2.gstatic.com
      encrypted-tbn3.gstatic.com
      lh3.googleusercontent.com

      # STUN (WebRTC NAT traversal)
      stun1.l.google.com
      stun2.l.google.com
      global.stun.twilio.com

      # Search autocomplete (transmits keystrokes as you type)
      suggestqueries.google.com

      # Google Workspace activity logging, AI panel, suggestions
      waa-pa.clients6.google.com
      appsgenaiserver-pa.clients6.google.com
      calendarsuggest.clients6.google.com

      # Analytics / crash telemetry
      app-measurement.com
      firebaselogging-pa.googleapis.com
      crashlyticsreports-pa.googleapis.com
      firebase-settings.crashlytics.com
      ||bugsnag.com^
      0.datadog.pool.ntp.org
      http-intake.logs.us5.datadoghq.com

      # Chrome optimization hints and on-device ML model fetch
      optimizationguide-pa.googleapis.com

      # Microsoft: Spotlight content feed, Office/Teams experimentation, Store
      fd.api.iris.microsoft.com
      ecs.office.com
      config.teams.microsoft.com
      storeedge.microsoft.com
      storeedgefd.dsx.mp.microsoft.com
      pti.store.microsoft.com
      displaycatalog-caching.bigcatalog-frontdoor-prod.commerce.microsoft.com
      displaycatalog.mp.microsoft.com
      msedge.api.cdp.microsoft.com

      # Windows Delivery Optimization bandwidth shaping
      tsfe.trafficshaping.dsp.mp.microsoft.com
      tsfecr.trafficshaping.dsp.mp.microsoft.com

      # Intel Driver & Support Assistant telemetry
      traces.optimize.intel.com

      # Mozilla Normandy / Shield studies (Remote Settings + CRLite stay allowed)
      normandy.tombstone.experimenter.prod.webservices.mozgcp.net
      normandy.cdn.mozilla.net
      classify-client.services.mozilla.com

      # Firefox OHTTP relay: ad attribution (PPA) and online Firefox Suggest
      prod.ohttp-gateway.prod.webservices.mozgcp.net

      # NVIDIA app telemetry and remote config
      ops-gx.nvidia.com
      localized-config-api.gx.nvidia.com

      # TCL vendor telemetry and launcher
      ||leiniao.com^
      ||huan.tv^
      ||cedock.com^
      ||tcllauncher.com^

      # Samsung / Bixby
      ca-odc.samsungapps.com
      odm.samsungcloud.com
      capi.samsungcloud.com
      ers.samsungcloud.com
      scs-use2.bixbyllm.com

      # Intercom support widget and session tracking
      ||intercom.io^
      ||intercomcdn.com^

      # DuckDuckGo ad serving and click tracking
      links.duckduckgo.com

      # GOG Galaxy store recommendations and feature flags
      recommendations-api.gog.com
      remote-config.gog.com

      # Meta
      payments-graph.facebook.com

      # Netflix
      ||netflix.com^

      # OneTrust cookie consent banners; a few sites gate content behind these
      ||onetrust.com^

      # Unidentified ad CDN; watch for breakage
      cdn.adapps.it

      # Unverified origin
      b.webresource.ca

      # Ads: UNTESTED with Tou.tv. Uncomment one at a time and verify playback.
      # imasdk.googleapis.com
      # pubads.g.doubleclick.net
      # googleads.g.doubleclick.net
      # pagead2.googlesyndication.com
    '';

    "allow/tv" = ''
      # TCL Google TV allow list (assign to TV group)
      # Keeps Tou.tv DRM, Jellyfin, and Play Store updates working
      # Last updated: 2026-10-31

      # Widevine provisioning, Play Store
      www.googleapis.com
      playatoms-pa.googleapis.com
    '';

    "allow/phone" = ''
      # Android phone allow list (assign to Phone group)
      # Last updated: 2026-10-31

      # Google APIs, Play Store
      www.googleapis.com
      playatoms-pa.googleapis.com

      # Push notifications
      mtalk.google.com
      alt1-mtalk.google.com
      alt2-mtalk.google.com
      alt3-mtalk.google.com
      alt4-mtalk.google.com
      alt5-mtalk.google.com
      alt6-mtalk.google.com
      alt7-mtalk.google.com
      alt8-mtalk.google.com

      # YouTube thumbnails
      i.ytimg.com
    '';

    "allow/guest" = ''
      # Guest allow list (assign to Guest group; guest VLAN arrives as the router, 192.168.0.1)
      # Keeps visitors' phones and laptops functional
      # Last updated: 2026-10-31

      # Google APIs, Play Store, contacts
      www.googleapis.com
      playatoms-pa.googleapis.com
      people-pa.googleapis.com
      androidpay-users-pa.googleapis.com
      chat.google.com

      # Push notifications
      mtalk.google.com
      alt1-mtalk.google.com
      alt2-mtalk.google.com
      alt3-mtalk.google.com
      alt4-mtalk.google.com
      alt5-mtalk.google.com
      alt6-mtalk.google.com
      alt7-mtalk.google.com
      alt8-mtalk.google.com
    '';

    "allow/work" = ''
      # Work laptop allow list (assign to Work group)
      # Keeps Google Workspace working: Meet, Calendar, Gmail, Google SSO
      # Last updated: 2026-10-31

      # Google APIs (OAuth token/userinfo for Sign in with Google, Workspace APIs)
      www.googleapis.com

      # Contacts / people chips and autocomplete in Gmail, Calendar, Meet
      people-pa.googleapis.com

      # Google Chat panel in Gmail
      chat.google.com

      # Calendar and Gmail notifications
      notifications-pa.googleapis.com
      calendarpushsubscription-pa.googleapis.com

      # Profile photos in Gmail, Calendar, Meet
      lh3.googleusercontent.com

      # YouTube thumbnails
      i.ytimg.com

      # Public IP lookup
      api.ipify.org
      api.seeip.org
    '';

    "allow/desktop" = ''
      # Desktop allow list (assign to Desktop group)
      # Keeps Gmail, Calendar, Drive, Meet and Sign in with Google working
      # Last updated: 2026-10-31

      # Google APIs: OAuth token/userinfo for Google SSO, plus the
      # Gmail/Calendar/Drive REST endpoints the web apps call
      www.googleapis.com

      # Contacts / people chips and autocomplete in Gmail, Calendar, Drive sharing
      people-pa.googleapis.com

      # Google Chat panel in Gmail
      chat.google.com

      # Calendar and Gmail notifications
      notifications-pa.googleapis.com
      calendarpushsubscription-pa.googleapis.com

      # Profile photos in Gmail, Calendar, Drive, Meet
      lh3.googleusercontent.com

      # YouTube thumbnails
      i.ytimg.com
    '';
  };
in {

  xdg.configFile = lib.mapAttrs' (name: text:
    lib.nameValuePair "pihole-lists/${name}.txt" { inherit text; }) lists;
}
