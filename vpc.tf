data "google_compute_regions" "regions-available" {

}
variable "custom-network" {
    type = string
    default = "custom-network"
}


resource "google_compute_network" "net1" {
    name                    = var.custom-network
    auto_create_subnetworks = "false"
}
resource "google_compute_subnetwork" "pub-subnets" {
    network = google_compute_network.net1.name
    count = length(data.google_compute_regions.regions-available.names)
    region = data.google_compute_regions.regions-available.names[count.index]
    name          = "${var.custom-network}-pub-subnet-${count.index + 1}"
    ip_cidr_range = "10.0.${count.index+1}.0/24"
  
}
resource "google_compute_subnetwork" "pvt-subnets" {
    network = google_compute_network.net1.name
    count = length(data.google_compute_regions.regions-available.names)-1
    region = data.google_compute_regions.regions-available.names[count.index]
    name          = "${var.custom-network}-pvt-subnet-${count.index + 1}"
    ip_cidr_range = "10.0.${count.index+51}.0/24"
  
}

