# Applications development

This directory contains the source code for the applications deployed into the cluster, 
with a subdirectory for each application, that contains must contain the following resources: 

- `src` directory, where the source code lives in.
- The `requirements.txt` file to track the application dependencies.
- A Dockerfile to build the application.
- A Makefile with all the necessary steps to build and publish the image container to a private ECR registry.
