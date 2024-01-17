{
  config,
  fetchurl,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (config.boot.loader) efi;

  uncompressed-fw = pkgs.callPackage
    ({ lib, runCommand, buildEnv, firmwareFilesList }:
      runCommand "qcom-modem-uncompressed-firmware-share"
        {
          firmwareFiles = buildEnv {
            name = "qcom-modem-uncompressed-firmware";
            paths = firmwareFilesList;
            pathsToLink = [
              "/lib/firmware/rmtfs"
              "/lib/firmware/qcom"
            ];
          };
        } ''
        PS4=" $ "
        (
        set -x
        mkdir -p $out/share/
        ln -s $firmwareFiles/lib/firmware/ $out/share/uncompressed-firmware
        )
      '')
    {
      firmwareFilesList = lib.flatten options.hardware.firmware.definitions;
    };

  linuxPackages_x13s = pkgs.linuxKernel.packageAliases.linux_latest;
  dtb = "${linuxPackages_x13s.kernel}/dtbs/qcom/sc8280xp-lenovo-thinkpad-x13s.dtb";
  linuxPackage = pkgs.linuxKernel.packageAliases.linux_latest;

  dtbName = "x13s-${linuxPackages_x13s.kernel.version}.dtb";
in {
  boot = {
    loader.systemd-boot.enable = true;
    loader.systemd-boot.extraFiles = {
      "${dtbName}" = dtb;
    };
    loader.efi.canTouchEfiVariables = true;
    loader.efi.efiSysMountPoint = "/boot";

    kernelPackages = linuxPackages_x13s;

    kernelParams = [
      "boot.shell_on_fail"
      "clk_ignore_unused"
      "pd_ignore_unused"
      "arm64.nopauth"
      "efi=noruntime"
      "cma=128M"
      "nvme.noacpi=1"
      "iommu.strict=0"
      "modprobe.blacklist=qcom_q6v5_pas" # for usb boot
      "console=tty0"
      "dtb=${dtbName}"
    ];
    initrd = {
      includeDefaultModules = false;
      availableKernelModules = [
        "i2c_hid"
        "i2c_hid_of"
        "i2c_qcom_geni"
        "leds_qcom_lpg"
        "pwm_bl"
        "qrtr"
        "pmic_glink_altmode"
        "gpio_sbu_mux"
        "phy_qcom_qmp_combo"
        "panel-edp"
        "msm"
        "phy_qcom_edp"
        "i2c-core"
        "i2c-hid"
        "i2c-hid-of"
        "i2c-qcom-geni"
        # "pcie-qcom"
        "phy-qcom-qmp-combo"
        "phy-qcom-qmp-pcie"
        "phy-qcom-qmp-usb"
        "phy-qcom-snps-femto-v2"
        "phy-qcom-usb-hs"
        "nvme"
      ];
    };
  };

  # power management, etc.
  environment.systemPackages = with pkgs; [
    qrtr
    qmic
    rmtfs
    pd-mapper
    uncompressed-fw
  ];
  environment.pathsToLink = [ "share/uncompressed-firmware" ];

  # ensure the x13s' dtb file is in the boot partition
  system.activationScripts.x13s-dtb = ''
    in_package="${dtb}"
    esp_tool_folder="${efi.efiSysMountPoint}/"
    in_esp="''${esp_tool_folder}${dtbName}"
    >&2 echo "Ensuring $in_esp in EFI System Partition"
    if ! ${pkgs.diffutils}/bin/cmp --silent "$in_package" "$in_esp"; then
      >&2 echo "Copying $in_package -> $in_esp"
      mkdir -p "$esp_tool_folder"
      cp "$in_package" "$in_esp"
      sync
    fi
  '';

  hardware.enableAllFirmware = true;
  hardware.firmware = [pkgs.linux-firmware (pkgs.callPackage ./pkgs/x13s-firmware.nix {})];
}
