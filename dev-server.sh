#!/bin/bash

# Development server script for Jekyll site
# Handles environment setup and starts Jekyll with live reload

set -e

# Set up Ruby gem environment
export GEM_HOME=$HOME/.gems
export PATH=$HOME/.gems/bin:$PATH

# Load environment variables from .env file
if [ -f .env ]; then
    echo "Loading environment variables from .env..."
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "Warning: .env file not found. Airtable integration may not work."
fi

# Start Jekyll development server
echo "Starting Jekyll development server..."
bundle exec jekyll serve --livereload --host 0.0.0.0 --port 4000