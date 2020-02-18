# nexus-aws
Creates a simple AWS code pipeline for your projects.

## Reference Architecture
TODO

## Prerequisites
- Github repo with the target application code
- Update variables.tf

## Usage
1. Create a new Terraform workspace. The workspace name will be used in subsequent resources.
2. Run Terraform Apply to create a CodeBuild project
3. Copy buildspec.yml to the new project Git directory