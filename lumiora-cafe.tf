terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "4787649586036097510"
  region  = "us-central1" 
}

# 1. Create the Custom VPC Network
resource "google_compute_network" "main_vpc" {
  name                    = "lumiora-vpc"
  auto_create_subnetworks = false
}

# 2. Create the Subnet
resource "google_compute_subnetwork" "public_subnet_1" {
  name          = "lumiora-subnet"
  ip_cidr_range = "10.0.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.main_vpc.id
}

# 3. Create the Firewall Rules (Allowing HTTP, SSH, and your API Port 3000)
resource "google_compute_firewall" "web_firewall" {
  name    = "lumiora-firewall"
  network = google_compute_network.main_vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3000"] 
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"]
}

# 4. Create the VM and Automate the Setup
resource "google_compute_instance" "game_vm" {
  name         = "lumioraapp"
  machine_type = "e2-standard-4" 
  zone         = "us-central1-a"   

  tags = ["web-server"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12" 
      size  = 20 # Giving a bit more space for Docker images
    }
  }

  # Attach to the new VPC we just created
  network_interface {
    network    = google_compute_network.main_vpc.name
    subnetwork = google_compute_subnetwork.public_subnet_1.name
    access_config {
      # This block assigns the public External IP
    }
  }

  # The Startup Script runs automatically when the VM boots for the first time
  metadata_startup_script = <<-EOT
    #!/bin/bash
    # 1. Install Docker and git
    sudo apt-get update -y
    sudo apt-get install -y git docker.io docker-compose
    sudo systemctl start docker
    sudo systemctl enable docker

    # 2. Clone the Lumiora repo
    cd /home/
    git clone https://github.com/rawrzar-sharp/lumiora.git
    cd lumiora

    # 3. Start the Docker containers
    sudo docker-compose up -d --build
  EOT
}

# 5. Output the Public IP so you know where to connect
output "lumiora_public_ip" {
  value       = google_compute_instance.game_vm.network_interface[0].access_config[0].nat_ip
  description = "The public IP address of your Lumiora server."
}