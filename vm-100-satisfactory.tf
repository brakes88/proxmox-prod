# VM 100: Satisfactory — nodo proxmox
# Configurazione ricostruita da qm config e terraform state show del 27/10/2026.
# Questa VM e gia presente e importata nello state: NON importarla di nuovo.
# MODALITA GESTITA: hardware e opzioni Proxmox sotto Terraform, salvo esclusioni mirate.
# NON eseguire apply prima di avere controllato un plan completo con ZERO differenze.
# Eseguire il backup delle VM e dello state prima di interventi su disco/hardware.
# QEMU creazione: 11.0.3; ctime=1786371344
# VM Generation ID (solo riferimento, non gestito qui): 2ee2609a-1c73-4997-83fb-ae056b205e4c
# ATTENZIONE: CPU affinity richiede privilegi root@pam se si vorra gestirla via provider.
resource "proxmox_virtual_environment_vm" "Satisfactory" {
  # Identita VM (indirizzo Terraform invariato rispetto a existing.tf)
  name      = "Satisfactory"
  node_name = var.proxmox_node
  vm_id     = 100

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
    cores    = 3
    sockets  = 1
    type     = "host"
    numa     = false
    affinity = "1,2,3"
  }

  # Memoria in MB (floating=0 disabilita ballooning)
  memory {
    dedicated = 17000
    floating  = 0
  }

  # Disco esistente: dichiarare i parametri, non creare/importare un altro disco
  # Volume attuale: local-lvm:vm-100-disk-0 (da qm config e dallo state)
  # path_in_datastore e sperimentale: qui non viene impostato per evitare
  # di modificare la semantica di collegamento del disco esistente.
  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 50
    file_format  = "raw"
    iothread     = true
    discard      = "ignore"
    ssd          = false
    backup       = true
    replicate    = true
    aio          = "io_uring"
    cache        = "none"
  }

  # CD-ROM attuale (ide2)
  cdrom {
    interface = "ide2"
    file_id   = "none"
  }

  # Interfaccia di rete net0 (MAC fisso gia presente in Proxmox)
  network_device {
    bridge      = "vmbr0"
    model       = "virtio"
    mac_address = "BC:24:11:F3:F7:FE"
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
    uuid = "8dce5ad9-09a5-4b9e-9df2-f4e1129ecae4"
  }

  # Evita riavvii automatici dopo le modifiche; alcune modifiche possono fallire
  # se richiedono arresto VM, finche non vengono effettuate in manutenzione.
  reboot_after_update = false

  lifecycle {
    prevent_destroy = true
    # Lo stato di accensione continua a essere controllato da Proxmox.
    # La CPU affinity richiede root@pam: ignoriamo SOLO questo attributo.
    ignore_changes = [
      started,
      # Il provider 0.118 non ha popolato questi blocchi nell'import precedente.
      # Non applicare differenze implicite a ISO/CD-ROM o identita SMBIOS.
      cdrom,
      smbios,
      cpu[0].affinity,
    ]
  }
}
