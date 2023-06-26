# Organization Infrastructure

This directory contains terraform resources that are typically built as pre-requisite for a specific project.
In a real-life scenario these resources are managed in a separated repository.


## Resources:

### ECR
The registry needs to be built before the of the initial image build, process that is not managed by terraform.
