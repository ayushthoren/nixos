{ ... }:
{
  services.libinput.enable = true;

  # Disable high-resolution scrolling for all devices
  environment.etc."libinput/local-overrides.quirks" = {
    text = ''
      [disablehighresolutionscrollingforreal]
      MatchName=*
      AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;
    '';
  };
}
