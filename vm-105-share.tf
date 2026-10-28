# VM 105: Share — nodo proxmox
# Configurazione ricostruita da qm config e terraform state show del 27/10/2026.
# Questa VM e gia presente e importata nello state: NON importarla di nuovo.
# MODALITA GESTITA: hardware e opzioni Proxmox sotto Terraform, salvo esclusioni mirate.
# NON eseguire apply prima di avere controllato un plan completo con ZERO differenze.
# Eseguire il backup delle VM e dello state prima di interventi su disco/hardware.
# QEMU creazione: 11.0.3; ctime=1792792952
# VM Generation ID (solo riferimento, non gestito qui): 3001add6-ad5a-4029-bae4-0f74f9fb8cf7
resource "proxmox_virtual_environment_vm" "Share" {
  # Identita VM (indirizzo Terraform invariato rispetto a existing.tf)
  name      = "Share"
  node_name = var.proxmox_node
  vm_id     = 105

  # Stato rilevato al momento della lettura e avvio automatico su Proxmox
  started  = true
  on_boot  = true
  template = false

  # Firmware, controller e boot
  bios          = "seabios"
  boot_order    = ["scsi0", "ide2", "net0"]
  scsi_hardware = "virtio-scsi-single"

  # Processore
  cpu {
    cores   = 2
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
  # Volume attuale: local-lvm:vm-105-disk-0 (da qm config e dallo state)
  # path_in_datastore e sperimentale: qui non viene impostato per evitare
  # di modificare la semantica di collegamento del disco esistente.
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20
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
    file_id   = "local:iso/debian-13.7.0-amd64-netinst.iso"
  }

  # Interfaccia di rete net0 (MAC fisso gia presente in Proxmox)
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "BC:24:11:7A:C9:B1"
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
    uuid = "38a166dc-4d45-46cc-93a1-48236df8a4a4"
  }

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
