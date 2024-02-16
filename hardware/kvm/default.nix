{ modulesPath, pkgs, lib, ... }:

{
  imports = [ (modulesPath + "/virtualisation/proxmox-image.nix") ];

  boot.initrd.availableKernelModules = [ "virtio_scsi" "sd_mod" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  proxmox.qemuConf = {
    bios = "ovmf";
    scsihw = "virtio-scsi-single";
  };

  boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_zen;

  zramSwap.enable = true;
}