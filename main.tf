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
  named_port {
    name = "http"
    port = 80
  }

  version {
    instance_template = google_compute_instance_template.temp1.self_link
  }

#   target_size  = 2

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

resource "google_compute_region_autoscaler" "myapp-autoscaler" {
  name   = "${var.image-name}autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.myappgroup1.self_link

  autoscaling_policy {
    max_replicas    = 10
    min_replicas    = 3
    cooldown_period = 60

    cpu_utilization {
      target = 0.6
    }
  }
}

# load balancer

resource "google_compute_backend_service" "lb-backend" {
  name                  = "${var.image-name}-backend-service-external"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL"
  health_checks = [google_compute_health_check.http-check.self_link]
  backend {
    group = google_compute_region_instance_group_manager.myappgroup1.instance_group
  }
  port_name = "http"

}

resource "google_compute_global_address" "default" {
  name = "lb-ip-address"
}
resource "google_compute_target_http_proxy" "default" {
  name        = "http-lb-proxy"
  provider    = google
  url_map     = google_compute_url_map.default.id
}
resource "google_compute_url_map" "default" {
  name            = "http-lb-map"
  default_service = google_compute_backend_service.lb-backend.id
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "http-lb"
  provider              = google
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "80"
  target                = google_compute_target_http_proxy.default.id
  ip_address            = google_compute_global_address.default.address
}