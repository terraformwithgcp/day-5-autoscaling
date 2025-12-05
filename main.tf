data "google_compute_image" "myappimage" {
    name = var.image-name
    project = var.project-id 
}


resource "google_compute_instance_template" "temp1" {
  name        = "${var.image-name}-template"
  description = "This template is used to create app server instances."

  instance_description = "description assigned to instances"
  machine_type         = "e2-medium"

  // Create a new boot disk from an image
  disk {
    source_image      = data.google_compute_image.myappimage.self_link
    auto_delete       = true
    boot              = true
    disk_size_gb     = 25
  }

  network_interface {
    network = var.network-name
    access_config {
      // Ephemeral IP
    }
  }
  tags = [ "http-server" ]

}