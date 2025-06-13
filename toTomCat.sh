#!/bin/bash

# cp "genie_frontend/src/main/webapp/config.props" "/usr/local/tomcat9/webapps/"
# cp -r "genie_frontend/src/main/java" "/usr/local/tomcat9/webapps/"

# # Define the folder path (replace with your folder path)
# SOURCE_FOLDER="genie_frontend/src/main/webapp/"

# # Define the name for the WAR file (e.g., your-app.war)
# WAR_FILE="/usr/local/tomcat9/webapps/genie.war"

# # Create the WAR file by zipping the contents of the folder
# jar -cvf "$WAR_FILE" -C "$SOURCE_FOLDER" .

# # Output the result
# echo "WAR file created successfully at $WAR_FILE"


cp "angular/config.props" "/usr/local/tomcat9/webapps/"

# Define the folder path (replace with your folder path)
SOURCE_FOLDER="angular/"

# Define the name for the WAR file (e.g., your-app.war)
WAR_FILE="/usr/local/tomcat9/webapps/genie.war"

# Create the WAR file by zipping the contents of the folder
jar -cvf "$WAR_FILE" -C "$SOURCE_FOLDER" .

# Output the result
echo "WAR file created successfully at $WAR_FILE"
