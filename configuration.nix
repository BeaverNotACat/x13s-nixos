{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports =
    [
      ./hardware-configuration.nix
      ./bootloader.nix
    ];

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "x13s";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  services.xserver.libinput.enable = true;

  hardware.bluetooth.enable = true;

  sound.enable = true;
  hardware.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    wireplumber.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };

  systemd.services = {
    pd-mapper = {
      unitConfig = {
        Requires = "qrtr-ns.service";
        After = "qrtr-ns.service";
      };
      serviceConfig = {
        Restart = "always";
        ExecStart = "${pkgs.pd-mapper}/bin/pd-mapper";
      };
      wantedBy = [
        "multi-user.target"
      ];
    };
    qrtr-ns = {
      serviceConfig = {
        ExecStart = "${pkgs.qrtr}/bin/qrtr-ns -f 1";
        Restart = "always";
      };
      wantedBy = ["multi-user.target"];
    };
    bluetooth = {
      serviceConfig = {
        ExecStartPre = [
          ""
          "${pkgs.util-linux}/bin/rfkill block bluetooth"
          "${pkgs.bluez5-experimental}/bin/btmgmt public-addr F4:A8:0D:30:A3:47"
          "${pkgs.util-linux}/bin/rfkill unblock bluetooth"
        ];
        ExecStart = [
          ""
          "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf --noplugin=sap"
        ];
      };
    };
  };

  users.users.username = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    packages = with pkgs; [ ];
    initialPassword = "changeme";
  };

  environment.systemPackages = with pkgs; [
    alsa-ucm-conf
    alsa-utils

    vim_configurable
    wget
    firefox
  ];

  system.stateVersion = "23.11";
}

