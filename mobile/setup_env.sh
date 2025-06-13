#!/bin/bash

# Define the .env file path
ENV_FILE=".env"

# Check if the .env file exists
if [ ! -f "$ENV_FILE" ]; then
  echo "Creating .env file..."
  cat <<EOL > $ENV_FILE
BASE_URL=put your base url
OPENAI_API_KEY=put your open ai api key
EOL
  echo ".env file created successfully!"
else
  echo ".env file already exists."
fi