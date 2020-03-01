resource "google_project" "ferrarimarco-iot-project" {
  name       = "ferrarimarco-iot"
  project_id = "ferrarimarco-iot"
  org_id     = "12569063409"
}

resource "google_project_service" "cloud-iot-apis" {
  project = google_project.ferrarimarco-iot-project.project_id
  service = "cloudiot.googleapis.com"

  disable_dependent_services = true

  depends_on = [
    google_project.ferrarimarco-iot-project
  ]
}

resource "google_project_service" "pubsub-apis" {
  project = google_project.ferrarimarco-iot-project.project_id
  service = "pubsub.googleapis.com"

  disable_dependent_services = true

  depends_on = [
    google_project.ferrarimarco-iot-project
  ]
}

resource "google_pubsub_topic" "default-devicestatus" {
  name    = "default-devicestatus"
  project = google_project.ferrarimarco-iot-project.project_id

  depends_on = [
    google_project.ferrarimarco-iot-project,
    google_project_service.pubsub-apis
  ]
}

resource "google_pubsub_topic" "default-telemetry" {
  name    = "default-telemetry"
  project = google_project.ferrarimarco-iot-project.project_id

  depends_on = [
    google_project.ferrarimarco-iot-project,
    google_project_service.pubsub-apis
  ]
}

resource "google_cloudiot_registry" "home-registry" {
  name    = "home-registry"
  project = google_project.ferrarimarco-iot-project.project_id

  depends_on = [
    google_project.ferrarimarco-iot-project,
    google_project_service.cloud-iot-apis,
    google_project_service.pubsub-apis
  ]

  event_notification_configs {
    pubsub_topic_name = google_pubsub_topic.default-telemetry.id
  }

  state_notification_config = {
    pubsub_topic_name = google_pubsub_topic.default-devicestatus.id
  }

  http_config = {
    http_enabled_state = "HTTP_ENABLED"
  }

  mqtt_config = {
    mqtt_enabled_state = "MQTT_ENABLED"
  }
}