variable "proxmox_node" {
  description = "Nome del nodo Proxmox"
  type        = string
}

variable "ssh_public_key" {
  description = "Chiave pubblica SSH per le nuove VM Linux"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDMzkBDbPliRhvTH0HHQ1BRPkoQcXMu+6vAblOfymilZTMMlrI20/8MxppKb4k9piXodsaT017JFpaacQGAbagS7N+PImDHJfWOMvMMe+tUMdJadkO6XbjXg1S6x7ndZj66wQ3c3HviCsEwk4jl6SHrhOIqmDHYB5x8A/6HITVe6rsXIWElzpqHPQ7gsZpafbWL1Rmz5zolXoAiOlNsZW8iD7c2ixGfqer03x9NTTgO/10mKWnhvFXgKxt1ZGKQLxBS1AeE+wjoT17woAe4rB9Sx/7BhiDRF5uXZB+GqMSlcivqaGodY6P+jm2YCpaFKIDYulmnGJEV9E9d6PwGc6+le6YIABIKZTq9kj3/r1WfLnqzH+E+PBGrAs8oGReppoYYX7PLqk21U2c4MtO4skt3qT17vPGvcEEi4XeAXHEOI08BcjTaaMVv0/Z0NLmrtzmuG6PeCDxntpG948p/p7pJ8N6voGfoYhfGWKsGSgZDmWsNHrJdiKnjNW7BHs7X8j0= brakes@BrakesGamingPC"
}