resource "google_logging_metric" "kpi_logging_metric_mysql_importer" {
  name            = "kpi-mysql-importer/metric"
  filter          = "resource.type=k8s_container AND resource.labels.container_name=mysql-importer-container AND jsonPayload.importedCount >= 0"
  value_extractor = "EXTRACT(jsonPayload.importedCount)"
  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "DISTRIBUTION"
  }
  bucket_options {
    linear_buckets {
      num_finite_buckets = 1
      width              = 1000000
      offset             = 0
    }
  }
}
