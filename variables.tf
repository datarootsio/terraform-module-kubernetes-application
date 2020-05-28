variable "name" {
  type        = string
  description = "The name of the deployment. Will be used for all other resources"
}

variable "namespace" {
  type        = string
  description = "The namespace where this deployment will live. Must exists."
}

variable "image" {
  type        = any
  description = "The image to deploy."
  default     = {}
}

variable "args" {
  type        = any
  description = "Arguments to pass to the container"
  default     = {}
}


variable "ports" {
  description = "Map of ports to expose, and associated settings."
  type        = any
  default     = {}
}

variable "environment_variables" {
  description = "Map of environment variables to inject in containers."
  type        = any
  default     = {}
}

variable "environment_variables_from_secret" {
  description = "Map of environment variables to inject in containers, from existing secrets."
  type        = any
  default     = {}
}

variable "resources_limits" {
  description = "Map of resources limits to assign to the container"
  default = {
    cpu    = "0.2"
    memory = "256Mi"
  }
}

variable "resources_requests" {
  description = "Map of resources requests to assign to the container"
  default = {
    cpu    = "0.1"
    memory = "128Mi"
  }
}

variable "image_pull_secrets" {
  description = "Map of image pull secrets to use with the containers"
  default     = {}
}

variable "liveness_probes" {
  description = "Map of liveness probes per container. Pass the regular terraform object as is : https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#liveness_probe-1"
  type        = any
  default     = {}
}

variable "readiness_probes" {
  description = "Map of readiness probes per container. Pass the regular terraform object as is : https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#readiness_probe-1"
  type        = any
  default     = {}
}

variable "volume_mounts" {
  description = "Map of volumes to mount."
  type        = any
  default     = {}
}

variable "volumes_mounts_from_config_map" {
  description = "Map of volumes to mount from config maps."
  type        = any
  default     = {}
}

variable "volumes_mounts_from_secret" {
  description = "Map of volumes to mount from secrets."
  type        = any
  default     = {}
}

variable "hpa" {
  description = "settings for the horizontal pod autoscaler"
  default = {
    enabled      = false
    target_cpu   = 80
    min_replicas = 2
    max_replicas = 6
  }
}

locals {

  linkerd_annotations = {
    "config.linkerd.io/proxy-cpu-limit"      = "0.75"
    "config.linkerd.io/proxy-cpu-request"    = "0.2"
    "config.linkerd.io/proxy-memory-limit"   = "768Mi"
    "config.linkerd.io/proxy-memory-request" = "128Mi"
  }

  ingress_annotations = {
    none = {}
    traefik = {
      "kubernetes.io/ingress.class" = "traefik"
      /*"traefik.ingress.kubernetes.io/redirect-entry-point" = "https"
      "traefik.ingress.kubernetes.io/redirect-permanent"   = "true"
      "ingress.kubernetes.io/ssl-redirect"                 = "true"
      "ingress.kubernetes.io/ssl-temporary-redirect"       = "false"*/
    }
  }

  ports_list = flatten([
    for container, portmap in var.ports : [
      for port, content in portmap : {
        "${container}-${port}" = merge(content, { "port" = port })
      }
    ]
  ])

  ports_map = { for item in local.ports_list :
    keys(item)[0] => values(item)[0]
  }

  volumes_list = flatten([
    for container, volume_map in var.volume_mounts : [
      for volume, content in volume_map : {
        "${container}-${volume}" = volume
      }
    ]
  ])

  volumes_map = { for item in local.volumes_list :
    keys(item)[0] => values(item)[0]
  }

  volumes_from_config_map_list = flatten([
    for container, volume_map in var.volumes_mounts_from_config_map : [
      for volume, content in volume_map : {
        "${container}-${volume}" = volume
      }
    ]
  ])

  volumes_from_config_maps_map = { for item in local.volumes_from_config_map_list :
    keys(item)[0] => values(item)[0]
  }

  volumes_from_secret_list = flatten([
    for container, volume_map in var.volumes_mounts_from_secret : [
      for volume, content in volume_map : {
        "${container}-${volume}" = volume
      }
    ]
  ])

  volumes_from_secrets_map = { for item in local.volumes_from_secret_list :
    keys(item)[0] => values(item)[0]
  }
}
