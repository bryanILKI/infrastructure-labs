resource "scaleway_instance_ip" "public_ip" {}

resource "scaleway_instance_server" "web" {
  type = "DEV1-S"
  image = "ubuntu_focal"
  ip_id = scaleway_instance_ip.public_ip.id
}