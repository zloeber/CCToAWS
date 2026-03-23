module "s3_static" {
  source      = "./modules/s3_static"
  bucket_name = var.static_bucket_name
}

module "ecr_shared" {
  source          = "./modules/ecr_shared"
  repository_name = var.ecr_repository_name
}

module "dynamodb_registry" {
  source     = "./modules/dynamodb_registry"
  table_name = "${var.name_prefix}-${var.environment}-registry"
}

module "control_plane" {
  source = "./modules/control_plane"

  name_prefix         = "${var.name_prefix}-${var.environment}"
  api_zip_path        = data.archive_file.api_lambda_zip.output_path
  reconcile_zip_path  = data.archive_file.reconcile_lambda_zip.output_path
  dynamodb_table_name = module.dynamodb_registry.table_name
  dynamodb_table_arn  = module.dynamodb_registry.table_arn
  ecr_repository_name = var.ecr_repository_name
  s3_bucket_name      = module.s3_static.bucket_id
  aws_region          = data.aws_region.current.id
  aws_account_id      = data.aws_caller_identity.current.account_id

  depends_on = [
    module.dynamodb_registry,
    module.s3_static,
  ]
}
