{ config, ... }:

let
  onePassword = "_d634138d-c276-4fc8-924b-40a0ea21d284_-browser-action";
  darkReader = "addon_darkreader_org-browser-action";
  uBlockOrigin = "ublock0_raymondhill_net-browser-action";
  cookieEditor = "_c3c10168-4186-445c-9c5b-63f12b8e2c87_-browser-action";
  videoDownloadHelper = "_b9db16a4-6edc-47ec-a1f4-b86292ed211d_-browser-action";
in
{
  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";

    policies = {
      # Extensions
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
        # Cookie-Editor
        "{c3c10168-4186-445c-9c5b-63f12b8e2c87}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/cookie-editor/latest.xpi";
          default_area = "navbar";
        };
        # Video Download Helper
        "{b9db16a4-6edc-47ec-a1f4-b86292ed211d}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/video-downloadhelper/latest.xpi";
          default_area = "navbar";
        };
      };

      # Privacy and telemetry
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableRemoteImprovements = true;
      CaptivePortal = false;
      NetworkPrediction = true;
      SearchSuggestEnabled = true;
      FirefoxSuggest = {
        WebSuggestions = false;
        SponsoredSuggestions = false;
        ImproveSuggest = false;
        OnlineEnabled = false;
        Locked = true;
      };
      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Category = "strict";
        Cryptomining = true;
        Fingerprinting = true;
        EmailTracking = true;
        SuspectedFingerprinting = true;
      };

      # Disable account/promotional features
      DisableAccounts = true;
      IPProtectionAvailable = false;
      VisualSearchEnabled = false;
      AIControls = {
        Default = {
          Value = "blocked";
          Locked = true;
        };
        Translations = {
          Value = "available";
          Locked = true;
        };
      };
      UserMessaging = {
        ExtensionRecommendations = false;
        FeatureRecommendations = false;
        UrlbarInterventions = false;
        SkipOnboarding = true;
        MoreFromMozilla = false;
        FirefoxLabs = false;
        Locked = true;
      };

      # Home and browser customization
      FirefoxHome = {
        Search = true;
        TopSites = false;
        SponsoredTopSites = false;
        Highlights = false;
        Stories = false;
        SponsoredStories = false;
        Widgets = {
          Enabled = false;
        };
        Locked = true;
      };
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
      NoDefaultBookmarks = true;
      DisableSetDesktopBackground = true;
      DisableFirefoxScreenshots = true;

      # Startup and package management
      DisableAppUpdate = true;
      DisableProfileImport = true;
      DontCheckDefaultBrowser = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";

      # Rendering
      HardwareAcceleration = true;
    };

    profiles.default = {
      id = 0;
      name = "default";
      path = "default";
      isDefault = true;
      settings = {
        # Crash reports are separate from telemetry
        "browser.crashReports.unsubmittedCheck.enabled" = false;
        "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
        "browser.tabs.crashReporting.sendReport" = false;
        "browser.tabs.crashReporting.includeURL" = false;

        # Vertical tabs
        "sidebar.revamp" = true;
        "sidebar.verticalTabs" = true;
        "sidebar.visibility" = "expand-on-hover";
        "sidebar.main.tools" = "passwords,syncedtabs,history,bookmarks";
        "sidebar.verticalTabs.dragToPinPromo.dismissed" = true;
        "sidebar.animation.expand-on-hover.duration-ms" = 100;
        "sidebar.animation.expand-on-hover.delay-duration-ms" = 0;

        # Toolbar layout
        "browser.uiCustomization.state" = builtins.toJSON {
          placements = {
            "widget-overflow-fixed-list" = [ ];
            "unified-extensions-area" = [ ];
            "nav-bar" = [
              "home-button"
              "vertical-spacer"
              "back-button"
              "forward-button"
              "stop-reload-button"
              "urlbar-container"
              "downloads-button"
              uBlockOrigin
              onePassword
              cookieEditor
              darkReader
              "unified-extensions-button"
              "sidebar-button"
            ];
            "toolbar-menubar" = [ "menubar-items" ];
            "TabsToolbar" = [ ];
            "vertical-tabs" = [ "tabbrowser-tabs" ];
            "PersonalToolbar" = [
              "import-button"
              "personal-bookmarks"
            ];
          };
          seen = [
            "developer-button"
            uBlockOrigin
            darkReader
            onePassword
            cookieEditor
            videoDownloadHelper
          ];
          dirtyAreaCache = [
            "nav-bar"
            "TabsToolbar"
            "vertical-tabs"
            "PersonalToolbar"
            "toolbar-menubar"
          ];
          currentVersion = 26;
          newElementCount = 0;
        };

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
  home.file.".mozilla/native-messaging-hosts".enable = false;
}
