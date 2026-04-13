{ ... }:
{
  home.sessionVariables = {
    # Avoid per-install profile rotation when Firefox store paths change
    MOZ_LEGACY_PROFILES = "1";
  };

  programs.firefox = {
    enable = true;

    policies = {
      ExtensionSettings = {
        # uBlock Origin
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          default_area = "navbar";
        };
        # 1Password
        "{d634138d-c276-4fc8-924b-40a0ea21d284}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/1password-x-password-manager/latest.xpi";
          default_area = "navbar";
        };
        # Dark Reader
        "addon@darkreader.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/darkreader/latest.xpi";
          default_area = "navbar";
        };
      };
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Pocket = false;
        Stories = false;
        SponsoredPocket = false;
        SponsoredStories = false;
        Snippets = false;
      };
      FirefoxSuggest = {
        SponsoredSuggestions = false;
      };
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      DisableFirefoxAccounts = true;
      DisableAccounts = true;
      DisableFirefoxScreenshots = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
    };

    profiles.default = {
      id = 0;
      name = "default";
      path = "default";
      isDefault = true;
      settings = {
        # Vertical tabs
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.visibility" = "expand-on-hover";
        "sidebar.main.tools" = "passwords,syncedtabs,history,bookmarks";
        "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;
        "sidebar.animation.expand-on-hover.duration-ms" = 100;
        "sidebar.animation.expand-on-hover.delay-duration-ms" = 0;

        # Persistence
        "browser.privatebrowsing.autostart" = false;
        "privacy.history.custom" = false;
        "places.history.enabled" = true;
        "network.cookie.lifetimePolicy" = 0;
        "privacy.sanitize.sanitizeOnShutdown" = false;
        "privacy.clearOnShutdown_v2.cookiesAndStorage" = false;
        "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = false;
        "privacy.clearOnShutdown_v2.cache" = false;
        "privacy.clearOnShutdown_v2.siteSettings" = false;
        "privacy.clearOnShutdown_v2.formdata" = false;
      };
    };
  };
}