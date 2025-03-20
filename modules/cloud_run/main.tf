resource "google_cloud_run_service_iam_policy" "noauth-games-ui" {
  location = "europe-west1"

  service     = google_cloud_run_v2_service.games-ui.name
  policy_data = data.google_iam_policy.noauth.policy_data
}
