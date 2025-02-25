packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.1"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "foundry-08" {
  ami_name      = "foundryvtt-${var.owner}"
  instance_type = "t3a.micro"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "foundry-base-0.1"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [var.owner_id]
  }
  ssh_username = "ec2-user"
}

variable "domain" {
  type = string
}

variable "owner" {
  type = string
}

variable "owner_id" {
  type = string
}

variable "name" {
  type    = string
  default = "www"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

build {
  name = "FoundryAMI"
  sources = [
    "sources.amazon-ebs.foundry-08"
  ]
  provisioner "file" {
    source      = "foundryvtt.zip"
    destination = "/tmp/foundryvtt.zip"
  }
  provisioner "file" {
    content = <<EOF
<VirtualHost _default_:443>
    ServerName              ${var.subdomain}.${var.domain}
    # Proxy Server Configuration
    ProxyPreserveHost       On
    ProxyPass "/socket.io/" "ws://localhost:30000/socket.io/"
    ProxyPass /             http://localhost:30000/
    ProxyPassReverse /      http://localhost:30000/
    ErrorLog logs/ssl_error_log
    TransferLog logs/ssl_access_log
    LogLevel warn
    SSLEngine on
    SSLProtocol all -SSLv3
    SSLCipherSuite HIGH:MEDIUM:!aNULL:!MD5:!SEED:!IDEA
    SSLCertificateFile /etc/pki/tls/certs/${var.domain}/cert.pem
    SSLCertificateKeyFile /etc/pki/tls/certs/${var.domain}/key.pem
    SSLCertificateChainFile /etc/pki/tls/certs/${var.domain}/fullchain.pem
</VirtualHost>
<VirtualHost *:80>
    ServerName              ${var.subdomain}.${var.domain}
    # Anything starting with a 'dot' might be part of the let's encrypt program. Don't redirect it
    <Location ~ "^/\..*$">
    </Location>
    # If it *doesn't start with a dot, then re-direct it to https.
    <Location ~ "(^$|^/[^\.].*$)">
        Redirect / https://${var.subdomain}.${var.domain}/join
    </Location>
</VirtualHost>
# Increase the maximum upload limit Apache will allow
<Location / >
# 100MB upload
LimitRequestBody 104857600 
</Location>
EOF
    destination = "/tmp/foundry.conf"
  }
  provisioner "file" {
    source      = "fstab"
    destination = "/tmp/fstab"
  }
  provisioner "file" {
    source      = "foundryvtt.service"
    destination = "/tmp/foundryvtt.service"
  }
  provisioner "shell" {
    script = "provision.sh"
  }
}

source "amazon-ebsvolume" "foundrydata" {
  instance_type = "t3a.micro"
  region        = var.region
  source_ami_filter {
    filters = {
      name                = "foundry-base-0.1"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = [var.owner_id]
  }
  ssh_username = "ec2-user"

  ebs_volumes {
    volume_type           = "gp3"
    device_name           = "/dev/sdb"
    delete_on_termination = false
    tags = {
      Name = "${var.owner}-foundry-data"
    }
    volume_size = 30
  }
}

build {
  name    = "FoundryData"
  sources = ["sources.amazon-ebsvolume.foundrydata"]
  provisioner "shell" {
    inline = [
      "sudo mkfs -t xfs /dev/sdb"
    ]
  }
}
