variable "name" {
  type        = string
  description = "The name of the deployment. Will be used for all other resources"
}

variable "namespace" {
  type        = string
  description = "The namespace where this deployment will live. Must exists."
}

variable "strategy" {
  type    = string
  default = "RollingUpdate"
}

variable "max_unavailable" {
  type    = string
  default = "25%"
}

variable "max_surge" {
  type    = string
  default = "25%"
}

variable "image" {
  type        = any
  description = "The image to deploy."
}

variable "replicas" {
  type        = number
  default     = 1
  description = "The number of replicas."
}

variable "inject_linkerd" {
  type        = bool
  default     = false
  description = "Add the necessary annotations for linkerd injection"
}

variable "host_aliases" {
  type    = map(list(string))
  default = {}
}

variable "args" {
  type        = any
  description = "Arguments to pass to the container"
  default     = {}
}

variable "command" {
  type        = any
  description = "Command that the container will run"
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

variable "annotations" {
  description = "Map of annotations to add on containers."
  type        = map(string)
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
  type        = list(string)
  description = "List of image pull secrets to use with the containers"
  default     = []
}

variable "liveness_probes" {
  description = "Map of liveness probes per container. Pass the regular terraform object as is : https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#liveness_probe-1"
  type        = any
}

variable "readiness_probes" {
  description = "Map of readiness probes per container. Pass the regular terraform object as is : https://www.terraform.io/docs/providers/kubernetes/r/deployment.html#readiness_probe-1"
  type        = any
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

variable "node_selector" {
  description = "Map of labels and values for node selection"
  type        = map(string)
  default     = {}
}

variable "hpa" {
  description = "settings for the horizontal pod autoscaler"
  type        = any
  default = {
    enabled      = false
    target_cpu   = 80
    min_replicas = 2
    max_replicas = 6
  }
}

variable "node_affinity" {
  type    = any
  default = {}
}

variable "pod_affinity" {
  type    = any
  default = {}
}

variable "pod_anti_affinity" {
  type    = any
  default = {}
}

locals {

  linkerd_annotations = {
    "linkerd.io/inject"                      = var.inject_linkerd ? "enabled" : "disabled",
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

  # This set of variables is to allow single containers with no "complex map" structure, to increase readability.
  # This is quite complex and with a lot of "terraformisms" but it works

  image = try(
    { (var.name) = tostring(var.image) },
    var.image,
  )

  single_container = can(tostring(var.image))

  args = try(
    { (var.name) = tolist(var.args) },
    var.args
  )

  command = try(
    { (var.name) = tolist(var.command) },
    var.command
  )

  ports                             = try(local.single_container ? { (var.name) = var.ports } : tomap(false), var.ports)
  readiness_probes                  = try(local.single_container ? { (var.name) = var.readiness_probes } : tomap(false), var.readiness_probes)
  liveness_probes                   = try(local.single_container ? { (var.name) = var.liveness_probes } : tomap(false), var.liveness_probes)
  environment_variables_from_secret = try(local.single_container ? { (var.name) = var.environment_variables_from_secret } : tomap(false), var.environment_variables_from_secret)
  annotations                       = try(var.inject_linkerd ? merge(local.linkerd_annotations, var.annotations) : var.annotations)
  environment_variables             = try(local.single_container ? { (var.name) = var.environment_variables } : tomap(false), var.environment_variables)
  resources_requests                = try(local.single_container ? { (var.name) = var.resources_requests } : tomap(false), var.resources_requests)
  resources_limits                  = try(local.single_container ? { (var.name) = var.resources_limits } : tomap(false), var.resources_limits)
  volume_mounts                     = try(local.single_container ? { (var.name) = var.volume_mounts } : tomap(false), var.volume_mounts)
  volumes_mounts_from_config_map    = try(local.single_container ? { (var.name) = var.volumes_mounts_from_config_map } : tomap(false), var.volumes_mounts_from_config_map)
  volumes_mounts_from_secret        = try(local.single_container ? { (var.name) = var.volumes_mounts_from_secret } : tomap(false), var.volumes_mounts_from_secret)

  # This set of variables merges all containers ports and volumes to assign them to the pod

  ports_list = flatten([
    for container, portmap in local.ports : [
      for port, content in portmap : {
        "${container}-${port}" = merge(content, { "port" = port })
      }
    ]
  ])

  ports_map = { for item in local.ports_list :
    keys(item)[0] => values(item)[0]
  }

  volumes_list = flatten([
    for container, volume_map in local.volume_mounts : [
      for volume, content in volume_map : {
        "${container}-${volume}" = volume
      }
    ]
  ])

  volumes_map = { for item in local.volumes_list :
    keys(item)[0] => values(item)[0]
  }

  volumes_from_config_map_list = flatten([
    for container, volume_map in local.volumes_mounts_from_config_map : [
      for volume, content in volume_map : {
        "${container}-${volume}" = volume
      }
    ]
  ])

  volumes_from_config_maps_map = { for item in local.volumes_from_config_map_list :
    keys(item)[0] => values(item)[0]
  }

  volumes_from_secret_list = flatten([
    for container, volume_map in local.volumes_mounts_from_secret : [
      for volume, content in volume_map : {
        "${container}-${volume}" = volume
      }
    ]
  ])

  volumes_from_secrets_map = { for item in local.volumes_from_secret_list :
    keys(item)[0] => values(item)[0]
  }
}
