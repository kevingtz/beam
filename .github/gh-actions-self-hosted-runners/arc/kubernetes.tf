#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
resource "kubectl_manifest" "arc_deployment" {
  yaml_body = file("config/arc_deployment.yaml")
  override_namespace = "arc"
  depends_on = [ helm_release.arc ]
}
resource "kubectl_manifest" "arc_deployment_demo" {
  yaml_body = file("config/arc_deployment_demo.yaml")
  override_namespace = "arc"
  depends_on = [ helm_release.arc ]
}
resource "kubectl_manifest" "arc_autoscaler" {
  yaml_body = file("config/arc_autoscaler.yaml")
  override_namespace = "arc"
  depends_on = [ helm_release.arc ]
}
resource "kubectl_manifest" "arc_autoscaler_demo" {
  yaml_body = file("config/arc_autoscaler_demo.yaml")
  override_namespace = "arc"
  depends_on = [ helm_release.arc ]
}
resource "kubectl_manifest" "arc_webhook_certificate" {
  yaml_body = file("config/arc_certificate.yaml")
  override_namespace = "arc"
  depends_on = [ helm_release.arc ]
}

# resource "kubernetes_cluster_role_binding" "user-to-cluster-admin" {
#   metadata {
#     name = "user-to-cluster-admin"
#   }
#   role_ref {
#     api_group = "rbac.authorization.k8s.io"
#     kind      = "ClusterRole"
#     name      = "cluster-admin"
#   }
#   subject {
#     kind      = "User"
#     name      = 
#     api_group = "rbac.authorization.k8s.io"
#   }
#   subject {
#     kind      = "ServiceAccount"
#     name      = "default"
#     namespace = "kube-system"
#   }
#   subject {
#     kind      = "Group"
#     name      = "system:masters"
#     api_group = "rbac.authorization.k8s.io"
#   }
# }