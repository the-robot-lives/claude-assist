# =============================================================================
# NetworkPolicy — restrict SMTP relay access to Mailu pods only.
# =============================================================================
# Prevents non-Mailu pods from reaching Postfix on port 25 (which relays all
# outbound mail through SendGrid). Services that need to send email should use
# SendGrid directly (smtp.sendgrid.net:587).
# =============================================================================
resource "kubernetes_network_policy_v1" "postfix_ingress_restrict" {
  metadata {
    name      = "postfix-ingress-restrict"
    namespace = local.ns
    labels    = local.common_labels
  }
  spec {
    pod_selector {
      match_labels = { app = "postfix" }
    }
    policy_types = ["Ingress"]
    ingress {
      # Only Mailu internal services — NOT roundcube (roundcube sends via front,
      # which enforces SMTP AUTH before forwarding to postfix).
      dynamic "from" {
        for_each = ["front", "admin", "rspamd", "dovecot"]
        content {
          pod_selector {
            match_labels = { app = from.value }
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 25
      }
      ports {
        protocol = "TCP"
        port     = 10025
      }
    }
  }
}

# =============================================================================
# NetworkPolicy — restrict SMTP submission on front to namespace-internal pods.
# =============================================================================
# Submission ports (465/587) on front are only reachable from within the
# platform-mail namespace (roundcube, admin). Inbound MX (port 25) and
# IMAP/POP3 remain open to all sources.
# =============================================================================
resource "kubernetes_network_policy_v1" "front_submission_restrict" {
  metadata {
    name      = "front-submission-restrict"
    namespace = local.ns
    labels    = local.common_labels
  }
  spec {
    pod_selector {
      match_labels = { app = "front" }
    }
    policy_types = ["Ingress"]

    # Allow submission (465/587) only from pods in this namespace.
    ingress {
      from {
        namespace_selector {
          match_labels = {
            "kubernetes.io/metadata.name" = local.ns
          }
        }
      }
      ports {
        protocol = "TCP"
        port     = 465
      }
      ports {
        protocol = "TCP"
        port     = 587
      }
    }

    # Allow all sources on non-submission ports (25, 80, 993, 995, 10025,
    # 10143, 2525, 4190) so inbound MX delivery and IMAP/POP3 still work.
    ingress {
      ports {
        protocol = "TCP"
        port     = 25
      }
      ports {
        protocol = "TCP"
        port     = 80
      }
      ports {
        protocol = "TCP"
        port     = 993
      }
      ports {
        protocol = "TCP"
        port     = 995
      }
      ports {
        protocol = "TCP"
        port     = 10025
      }
      ports {
        protocol = "TCP"
        port     = 10143
      }
      ports {
        protocol = "TCP"
        port     = 2525
      }
      ports {
        protocol = "TCP"
        port     = 4190
      }
    }
  }
}
