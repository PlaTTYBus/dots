{
  packages =
    {
      inputs,
      pkgs,
      lib,
      ...
    }:
    let
      # divine orb style :)
      important_style = "bg:white fg:bold #ff0000";

      # rounded pill segment, uses the named terminal colors so it follows the noctalia color scheme
      pill = color: content: "[](${color})[${content}](bold fg:black bg:${color})[](${color})";
    in
    {
      starship = inputs.wrappers.wrappers.starship.wrap {
        inherit pkgs;
        settings = {
          add_newline = false;
          format = lib.concatStrings [
            "$username"
            "$hostname"
            "$directory"
            "$git_branch"
            "$git_state"
            "$git_status"
            "$nix_shell"
            "$character"
          ];
          right_format = lib.concatStrings [
            "$cmd_duration"
            "$localip"
          ];

          # modules
          character = {
            error_symbol = "[ ](bold red)";
            success_symbol = "[](purple)";
            vimcmd_symbol = "[](green)";
          };
          # only shown as root or over ssh
          username = {
            style_root = important_style;
            style_user = important_style;
            format = "[ $user ]($style) ";
          };
          hostname = {
            ssh_only = false;
            ssh_symbol = "󰣀 ";
            format = "${pill "purple" "󰒋 $ssh_symbol$hostname"} ";
          };
          directory = {
            truncation_length = 3;
            truncate_to_repo = true;
            read_only = " ";
            format = "${pill "blue" " $path$read_only"} ";
          };
          git_branch = {
            symbol = "";
            format = "[$symbol $branch]($style) ";
            style = "yellow";
          };
          git_state = {
            format = "([$state( $progress_current/$progress_total)]($style)) ";
            style = "bright-black";
          };
          git_status = {
            conflicted = "​";
            deleted = "​";
            format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style) ";
            modified = "​";
            renamed = "​";
            staged = "​";
            stashed = "≡";
            style = "cyan";
            untracked = "​";
          };
          nix_shell = {
            format = "[$symbol]($style) ";
            symbol = "";
            style = "bright-magenta";
          };

          # right prompt
          # runtime of the last command, shown when it took longer than half a second
          cmd_duration = {
            min_time = 500;
            format = "[ $duration]($style) ";
            style = "yellow";
          };
          # local ip address, hidden when not connected
          localip = {
            disabled = false;
            ssh_only = false;
            format = "[󰩟 $localipv4]($style)";
            style = "cyan";
          };
        };
      };
    };

  config =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          inherit (pkgs.custom) starship;
        })
      ];

      # NOTE: starship is initialized in the fish wrapper

      custom.programs.print-config = {
        starship = /* sh */ "moor ${pkgs.starship.configuration.constructFiles."starship.toml"}";
      };
    };
}
