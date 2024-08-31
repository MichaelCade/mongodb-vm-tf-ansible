provider "vsphere" {
  user           = "administrator@vzilla.local"
  password       = "Passw0rd999!"
  vsphere_server = "192.168.169.181"

  # If you have a self-signed cert
  allow_unverified_ssl = true
}

data "vsphere_datacenter" "dc" {
  name = "vZilla DC"
}

data "vsphere_datastore" "datastore" {
  name          = "NETGEAR716"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = "vZilla Cluster"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = "VM Network"
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = "ubuntu-2204"
  datacenter_id = data.vsphere_datacenter.dc.id
}

resource "vsphere_virtual_machine" "vm" {
  count            = 3
  name             = "mongo-node-${count.index + 1}"
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  firmware         = "efi" 
  
  num_cpus = 2
  memory   = 4096
  guest_id = data.vsphere_virtual_machine.template.guest_id

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template.disks.0.size
    eagerly_scrub    = false
    thin_provisioned = true
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    timeout = "120"

    customize {
      linux_options {
        host_name = "mongo-node-${count.index + 1}"
        domain    = "local"
      }

      network_interface {
        ipv4_address = "192.168.169.${count.index + 101}"
        ipv4_netmask = 24
      }

      ipv4_gateway = "192.168.169.1"
    }
  }
}