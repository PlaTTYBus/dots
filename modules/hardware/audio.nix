{
  pkgs,
  ...
}:
let
  mute-all = pkgs.writeShellApplication {
    name = "mute-all";
    runtimeInputs = with pkgs; [
      jq
      libnotify
      pulseaudio
    ];
    text = /* sh */ ''
      if pactl -f json list sinks | jq -e 'any(.[]; .mute == false)' >/dev/null; then
        state=1
        title="Audio muted"
      else
        state=0
        title="Audio unmuted"
      fi

      for kind in sink source; do
        pactl -f json list "''${kind}s" | jq -r '.[].name' | while read -r name; do
          pactl "set-$kind-mute" "$name" "$state"
        done
      done

      notify-send -a "Audio" -i audio-volume-muted "$title"
    '';
  };
in
{
  # setup pipewire for audio
  security.rtkit.enable = true;
  services = {
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    pamixer
    pavucontrol
    mute-all
  ];
}
