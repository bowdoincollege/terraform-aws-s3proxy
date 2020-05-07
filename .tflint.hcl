
config {
  deep_check = true
  force      = false

  aws_credentials = {
    region = "us-east-1" # provide default until tflint parses provider block
  }
}

rule "terraform_dash_in_data_source_name" { enabled = true }
rule "terraform_dash_in_module_name" { enabled = true }
rule "terraform_dash_in_output_name" { enabled = true }
rule "terraform_dash_in_resource_name" { enabled = true }
rule "terraform_documented_outputs" { enabled = true }
rule "terraform_documented_variables" { enabled = true }
rule "terraform_module_pinned_source" { enabled = true }
