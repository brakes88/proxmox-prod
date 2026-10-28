# VM 104: Jellyfin — nodo proxmox
# Configurazione ricostruita da qm config e terraform state show del 27/10/2026.
# Questa VM e gia presente e importata nello state: NON importarla di nuovo.
# MODALITA GESTITA: hardware e opzioni Proxmox sotto Terraform, salvo esclusioni mirate.
# NON eseguire apply prima di avere controllato un plan completo con ZERO differenze.
# Eseguire il backup delle VM e dello state prima di interventi su disco/hardware.
# QEMU creazione: 11.0.3; ctime=1791871810
# VM Generation ID (solo riferimento, non gestito qui): 93e89bd8-3ed0-428c-9409-2d3f0627866f
# ATTENZIONE: PCI passthrough hostpci0 e USB 2-1 sono critici per Jellyfin.
# La gestione del campo hostpci.id tramite API token NON e supportata dal provider:
# per modificarlo in futuro serve una strategia di mapping o credenziali appropriate.
resource "proxmox_virtual_environment_vm" "Jellyfin" {
  # Identita VM (indirizzo Terraform invariato rispetto a existing.tf)
  name      = "Jellyfin"
  node_name = var.proxmox_node
  vm_id     = 104

  # Stato rilevato al momento della lettura e avvio automatico su Proxmox
  started  = true
  on_boot  = true
  template = false

  # Firmware, controller e boot
  bios          = "seabios"
  boot_order    = ["scsi0", "ide2", "net0"]
  scsi_hardware = "virtio-scsi-single"
  machine       = "q35"

  # Processore
  cpu {
    cores   = 4
    sockets = 1
    type    = "host"
    numa    = false
  }

  # Memoria in MB (floating=0 disabilita ballooning)
  memory {
    dedicated = 12288
    floating  = 4096
  }

  # Disco esistente: dichiarare i parametri, non creare/importare un altro disco
  # Volume attuale: local-lvm:vm-104-disk-0 (da qm config e dallo state)
  # path_in_datastore e sperimentale: qui non viene impostato per evitare
  # di modificare la semantica di collegamento del disco esistente.
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 40
    file_format  = "raw"
    iothread     = true
    discard      = "on"
    ssd          = false
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
    mac_address = "BC:24:11:14:F2:50"
    firewall    = false
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
    uuid = "c4b7e311-a565-49be-9e70-a8e8d84b38c2"
  }

  # Ordine di avvio allo startup dell'host
  startup {
    order    = 1
    up_delay = 90
  }

  # Passthrough PCI esistente (richiede attenzione ai permessi di modifica)
  hostpci {
    device = "hostpci0"
    id     = "0000:00:02.0"
    pcie   = true
  }

  # Passthrough USB esistente
  usb {
    host = "2-1"
    usb3 = false
  }

  # Evita riavvii automatici dopo le modifiche; alcune modifiche possono fallire
  # se richiedono arresto VM, finche non vengono effettuate in manutenzione.
  reboot_after_update = false

  lifecycle {
    prevent_destroy = true
    # Lo stato di accensione continua a essere controllato da Proxmox.
    # Passthrough PCI/USB: non riconfigurarli con il token API attuale.
    ignore_changes = [
      started,
      # Il provider 0.118 non ha popolato questi blocchi nell'import precedente.
      # Non applicare differenze implicite a ISO/CD-ROM o identita SMBIOS.
      cdrom,
      smbios,
      hostpci,
      usb,
    ]
  }
}
