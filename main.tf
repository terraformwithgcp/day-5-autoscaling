data "google_compute_image" "myappimage" {
    name = var.image-name
    project = var.project-id 
}

data "google_compute_zones" "allzones" {
    region = var.region  
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


resource "google_compute_region_instance_group_manager" "myappgroup1" {
  name = "${var.image-name}-igm"

  base_instance_name         = "mycustomapp"
  region                     = var.region
  distribution_policy_zones  = data.google_compute_zones.allzones.names

  version {
    instance_template = google_compute_instance_template.temp1.self_link
  }

  target_size  = 2

  auto_healing_policies {
    health_check      = google_compute_health_check.http-check.self_link
    initial_delay_sec = 60
  }
}

resource "google_compute_health_check" "http-check" {
    name               = "http-basic-check"
    check_interval_sec = 10
    timeout_sec        = 5
    healthy_threshold  = 2
    unhealthy_threshold = 2
    
    http_health_check {
        port               = 80
        request_path       = "/"
    }
  
}