{ lib, ... }:
let
  archiveMimeTypes = [
    "application/zip"
    "application/x-zip-compressed"
    "application/x-7z-compressed"
    "application/vnd.rar"
    "application/x-rar-compressed"
    "application/x-tar"
    "application/x-compressed-tar"
    "application/gzip"
    "application/x-gzip"
    "application/x-bzip"
    "application/x-bzip2"
    "application/x-xz"
    "application/zstd"
    "application/x-zstd-compressed-tar"
    "application/java-archive"
  ];
in
{
  xdg = {
    enable = true;
    mimeApps.enable = true;
    mimeApps.defaultApplications = {
      "application/pdf" = [ "firefox.desktop" ];
      "application/xhtml+xml" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "text/xml" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];

      "inode/directory" = [ "thunar.desktop" ];
      "text/plain" = [ "code.desktop" ];

      "image/jpeg" = [ "org.kde.gwenview.desktop" ];
      "image/png" = [ "org.kde.gwenview.desktop" ];
      "image/gif" = [ "org.kde.gwenview.desktop" ];
      "image/webp" = [ "org.kde.gwenview.desktop" ];
      "image/tiff" = [ "org.kde.gwenview.desktop" ];
      "image/svg+xml" = [ "org.kde.gwenview.desktop" ];

      "video/mp4" = [ "vlc.desktop" ];
      "video/x-matroska" = [ "vlc.desktop" ];
      "video/webm" = [ "vlc.desktop" ];
      "video/x-msvideo" = [ "vlc.desktop" ];
      "audio/mpeg" = [ "vlc.desktop" ];
      "audio/ogg" = [ "vlc.desktop" ];
      "audio/flac" = [ "vlc.desktop" ];
      "audio/wav" = [ "vlc.desktop" ];

      "application/x-bittorrent" = [ "org.qbittorrent.qBittorrent.desktop" ];
    } // lib.genAttrs archiveMimeTypes (_: [ "org.kde.ark.desktop" ]);
    mimeApps.associations.removed =
      lib.genAttrs archiveMimeTypes (_: [ "prismlauncher.desktop" ]);
  };
}
