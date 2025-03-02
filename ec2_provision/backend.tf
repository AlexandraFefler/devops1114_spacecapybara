terraform {
  backend "gcs" {
    bucket  = "spacecapy_bucket"
    prefix  = "terraform/state"  # Folder path inside the bucket
  }
}
