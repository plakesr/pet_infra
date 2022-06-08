terraform {
  backend "s3" {
    bucket = "mypetbuckettw"
    key    = "tf-state"
    region = "us-east-1"
  }
}