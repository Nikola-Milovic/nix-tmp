{
  options,
  config,
  pkgs,
  namespace,
  lib,
  ...
}:
let
  inherit (lib) types mkEnableOption mkIf;
  cfg = config.${namespace}.programs.terminal.starship;
in
{
  options.${namespace}.programs.terminal.starship = with types; {
    enable = mkEnableOption "starship";
  };

  # TODO: add more languages and nerdfont icons (check out presets on their docs)
  # https://gist.github.com/3ayazaya/d87c70c5f30a6e28f15dfc84ca95fc68
  config = mkIf cfg.enable {
    # Prompt issues
    home.packages = [ pkgs.bashInteractive ];

    programs.starship = {
      enable = true;
      settings = {
        character = {
          success_symbol = "[➜](bold purple)";
          error_symbol = "[➜](bold red)";
        };

        kubernetes = {
          disabled = false;
        };

        git_branch.format = "on [$symbol$branch(:$remote_branch)]($style) ";

        nix_shell = {
          symbol = " ";
        };

        add_newline = false;
        aws.disabled = true;
        gcloud.disabled = true;
        line_break.disabled = true;
      };
    };

  };
}
