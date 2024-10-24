{
  lib,
  config,
  namespace,
  ...
}:
with lib;
with lib.${namespace};
let
  cfg = config.system.impermanence;
in
{
  options.system.impermanence = with types; {
    enable = mkBoolOpt false "Whether or not to enable impermanence.";
    # TODO: home impermanence
    home = mkBoolOpt false "Whether or not to enable impermanence for /home as well.";
  };

  config = mkIf cfg.enable {
    security.sudo.extraConfig = ''
      # rollback results in sudo lectures after each reboot
      Defaults lecture = never
    '';

    programs.fuse.userAllowOther = true;

    boot.initrd.systemd.services.rollback = {
      description = "Simplified Rollback BTRFS root subvolume to a pristine state";
      wantedBy = [ "initrd.target" ];
      before = [
        "initrd-root-fs.target"
        "sysroot-var-lib-nixos.mount"
      ];
      after = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /btrfs_tmp
        mount /dev/sda2 -o subvol=/ /btrfs_tmp

        # Move current root to a single backup location
        if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_root
          echo "Moving current root to /btrfs_tmp/old_root"
          rm -rf /btrfs_tmp/old_root
          mv /btrfs_tmp/root /btrfs_tmp/old_root
        fi

        # Create a fresh root subvolume
        btrfs subvolume create /btrfs_tmp/root
        echo "Created fresh /root subvolume"

        # Optionally create a new /home subvolume if enabled
        ${optionalString cfg.home ''
          if [[ -e /btrfs_tmp/home ]]; then
            echo "Moving current /home to /btrfs_tmp/old_home"
            rm -rf /btrfs_tmp/old_home
            mv /btrfs_tmp/home /btrfs_tmp/old_home
          fi
          btrfs subvolume create /btrfs_tmp/home
          echo "Created fresh /home subvolume"
        ''}

        umount /btrfs_tmp
      '';
    };

    environment.persistence."/persist" = {
      hideMounts = true;
      directories = [
        "/srv"
        "/.cache/nix/"
        "/etc/NetworkManager/system-connections"
        "/var/cache/"
        "/var/db/sudo/"
        "/var/lib/"
      ];
      files = [
        "/etc/machine-id"
        "/etc/ssh/ssh_host_ed25519_key"
        "/etc/ssh/ssh_host_ed25519_key.pub"
        "/etc/ssh/ssh_host_rsa_key"
        "/etc/ssh/ssh_host_rsa_key.pub"
      ];
    };

    fileSystems."/persist".neededForBoot = true;
    fileSystems."/var/log".neededForBoot = true;
  };
}
