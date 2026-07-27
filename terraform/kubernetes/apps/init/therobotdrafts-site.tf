# ---------------------------------------------------------------------------
# The Robot Drafts (vnext) — Phoenix API + Next.js frontend (start-app scaffold).
# Served at draft.therobotplans.com, riding the existing therobotplans.com zone.
# The apex, app. and api. hosts on that zone serve the therobotplans app and are
# untouched here.
# ---------------------------------------------------------------------------
# Deployed by hand via deploy-service/helm-upgrade (chart
# projects/therobotdrafts/vnext/app/helm/therobotdrafts); no helm_release here,
# matching the retired foryou pattern.
#
# The InfisicalSecret for /apps/therobotdrafts (-> therobotdrafts-secrets) is
# owned by the CHART, not terraform: the chart templates the same
# `infisical-therobotdrafts-secrets` object, and the first helm install
# (2026-07-27) refused to adopt a terraform-labeled copy. The TF resource that
# briefly lived here was deleted from the cluster and must be removed from
# state (`state rm kubectl_manifest.infisical_therobotdrafts_secrets`) if it
# still lingers there.
#
# The app-timescaledb app_db_secrets_map["THEROBOTDRAFTS"] mount therefore
# depends on the chart being installed before any timescaledb rollout that
# consumes THEROBOTDRAFTS_DB_USER / _DB_PASSWORD.
#
# TLS (/apps/tls/therobotdrafts -> therobotdrafts-tls) is likewise declared by
# the chart's own tls-secret.yaml template — same as foryou-site.tf.
