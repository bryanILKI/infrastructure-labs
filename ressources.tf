
# PRIVATE NETWORK
resource "scaleway_vpc_private_network" "pn_priv" {
    name = "subnet_agora"
    
}

# SECURITY GROUP
resource "scaleway_instance_security_group" "allow_all" {
    inbound_default_policy = "accept"
    outbound_default_policy = "accept"
}

# MASTERS
resource "scaleway_instance_server" "master" {
  count = var.nb_master
  name = "master-${count.index}"
  type = "DEV1-M"
  image = "ubuntu_focal"
  
  security_group_id = scaleway_instance_security_group.allow_all.id
  private_network {
    pn_id = scaleway_vpc_private_network.pn_priv.id
  }
}

# WORKERS
resource "scaleway_instance_server" "worker" {
  count = var.nb_worker
  name = "worker-${count.index}"
  type = "DEV1-L"
  image = "ubuntu_focal"
  
  security_group_id = scaleway_instance_security_group.allow_all.id
  private_network {
    pn_id = scaleway_vpc_private_network.pn_priv.id
  }
}

# DEPLOY
resource "scaleway_instance_ip" "deploy_public_ip" {}

resource "scaleway_instance_server" "deploy" {
  name = "deploy"
  type = "DEV1-L"
  image = "ubuntu_focal"
  ip_id = scaleway_instance_ip.deploy_public_ip.id

    user_data = {
    foo        = "bar"
    cloud-init = file("ssh-key.sh")
  }
  
  security_group_id = scaleway_instance_security_group.allow_all.id
  private_network {
    pn_id = scaleway_vpc_private_network.pn_priv.id
  }
}

output "deploy_public_ip" {
  value = scaleway_instance_server.deploy.public_ip
}

# LB 
resource "scaleway_lb_ip" "ip" {
}

resource "scaleway_lb" "lb" {
  ip_id  = scaleway_lb_ip.ip.id
  zone = "fr-par-1"
  type   = "LB-S"
  release_ip = false

  private_network {
    private_network_id = scaleway_vpc_private_network.pn_priv.id
  }
}

resource "scaleway_lb_backend" "backend01" {
  lb_id            = scaleway_lb.lb.id
  name             = "lb_backend"
  forward_protocol = "http"
  forward_port     = "6443"
}

output "lb_public_ip" {
  value = scaleway_lb.lb.ip_address
}