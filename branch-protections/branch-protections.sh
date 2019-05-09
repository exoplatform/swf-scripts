#!/bin/bash

echo "Preparing docker image..."
docker build -t branch-protections .

echo "Launching container..."
docker run -ti --rm branch-protections 
