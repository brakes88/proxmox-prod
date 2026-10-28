# VM 101: AdGuardHome — nodo proxmox
# Configurazione ricostruita da qm config e terraform state show del 27/10/2026.
# Questa VM e gia presente e importata nello state: NON importarla di nuovo.
# MODALITA GESTITA: hardware e opzioni Proxmox sotto Terraform, salvo esclusioni mirate.
# NON eseguire apply prima di avere controllato un plan completo con ZERO differenze.
# Eseguire il backup delle VM e dello state prima di interventi su disco/hardware.
# QEMU creazione: 10.0.2; ctime=1754844621
# VM Generation ID (solo riferimento, non gestito qui): e93de099-7746-45e8-8634-1468faa58207
resource "proxmox_virtual_environment_vm" "AdGuardHome" {
  # Identita VM (indirizzo Terraform invariato rispetto a existing.tf)
  name      = "AdGuardHome"
  node_name = var.proxmox_node
  vm_id     = 101

  # Stato rilevato al momento della lettura e avvio automatico su Proxmox
  started  = false
  on_boot  = true
  template = false

  # Firmware, controller e boot
  bios          = "seabios"
  boot_order    = ["scsi0", "ide2", "net0"]
  scsi_hardware = "virtio-scsi-single"

  # Processore
  cpu {
    cores   = 1
    sockets = 1
    type    = "x86-64-v2-AES"
    numa    = false
  }

  # Memoria in MB (floating=0 disabilita ballooning)
  memory {
    dedicated = 2048
    floating  = 0
  }

  # Disco esistente: dichiarare i parametri, non creare/importare un altro disco
  # Volume attuale: local-lvm:vm-101-disk-0 (da qm config e dallo state)
  # path_in_datastore e sperimentale: qui non viene impostato per evitare
  # di modificare la semantica di collegamento del disco esistente.
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 8
    file_format  = "raw"
    iothread     = true
    discard      = "ignore"
    ssd          = true
    backup       = true
    replicate    = true
    aio          = "io_uring"
    cache        = "none"
  }

  # CD-ROM attuale (ide2)
  cdrom {
    interface = "ide2"
    file_id   = "local:iso/debian-12.11.0-amd64-netinst.iso"
  }

  # Interfaccia di rete net0 (MAC fisso gia presente in Proxmox)
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "BC:24:11:F3:7D:94"
    firewall    = true
  }

  # QEMU guest agent e sistema operativo
  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  # Identificativo SMBIOS gia esistente
  smbios {
    uuid = "99cab625-7b2b-488a-96c1-159da21e989c"
  }

  tags = ["docker", "security"]

  # Evita riavvii automatici dopo le modifiche; alcune modifiche possono fallire
  # se richiedono arresto VM, finche non vengono effettuate in manutenzione.
  reboot_after_update = false

  lifecycle {
    prevent_destroy = true
    # Lo stato di accensione continua a essere controllato da Proxmox.
    ignore_changes = [
      started,
      # Il provider 0.118 non ha popolato questi blocchi nell'import precedente.
      # Non applicare differenze implicite a ISO/CD-ROM o identita SMBIOS.
      cdrom,
      smbios,
    ]
  }
}
