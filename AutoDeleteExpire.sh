#!/bin/bash

# Set the HOST variable
HOST="http://192.168.2.10:8080"

# Define API URLs
FETCH_API_URL="$HOST/api/v2/torrents/info"
DELETE_API_URL="$HOST/api/v2/torrents/delete"

# Check if category argument is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <category>"
  exit 1
fi

CATEGORY="$1"

# Fetch torrents info from API
response=$(curl -s "$FETCH_API_URL")

# Check if the request was successful
if [ $? -ne 0 ]; then
  echo "Failed to fetch data from API"
  exit 1
fi

# Get current timestamp
current_time=$(date +%s)

# Calculate the timestamp for 30 days ago
thirty_days_ago=$((current_time - 30*24*60*60))

# Parse and display the JSON response using jq, filtered by provided category and completion_on < 30 days ago
filtered_response=$(echo "$response" | jq --argjson thirty_days_ago "$thirty_days_ago" --arg category "$CATEGORY" '[.[] | select(.category == $category and .completion_on < $thirty_days_ago)] | sort_by(.completion_on)')

# Count the number of matching torrents
matching_count=$(echo "$filtered_response" | jq 'length')

# Display the number of matching torrents
echo "Number of matching torrents: $matching_count"

# Check if there are any torrents in the filtered response
if [ "$matching_count" -eq 0 ]; then
  echo "No torrents found with category '$CATEGORY' and completion_on > 30 days ago"
  exit 0
fi

# Extract and display the names and infohashes of matching torrents
echo "The following torrents in category '$CATEGORY' are eligible for deletion:"
echo "$filtered_response" | jq -r '.[] | "Name: \(.name), Infohash: \(.infohash_v1)"'

# Prompt user for confirmation
read -p "Do you want to delete these torrents? (y/n): " confirmation

# Check user's input
if [ "$confirmation" != "y" ]; then
  echo "Deletion cancelled by user."
  exit 0
fi

# Initialize delete count
delete_count=0

# Loop through each torrent in the filtered response
echo "$filtered_response" | jq -r '.[] | @base64' | while read -r torrent; do
  # Decode the base64-encoded torrent JSON
  torrent_json=$(echo "$torrent" | base64 --decode)
  
  # Extract infohash and name
  infohash=$(echo "$torrent_json" | jq -r '.infohash_v1')
  name=$(echo "$torrent_json" | jq -r '.name')
  
  # Send POST request to delete the torrent
  delete_response=$(curl -s -X POST "$DELETE_API_URL" --data-urlencode "hashes=$infohash" --data-urlencode "deleteFiles=true")

  # Check if the delete request was successful
  if [ $? -ne 0 ]; then
    echo "Failed to send delete request to API for $name"
    continue
  fi
  
  # Increment delete count
  delete_count=$((delete_count + 1))
  
  # Clear current line and move cursor to beginning
  echo -en "\r\033[K"
  
  # Print deleting message without newline
  echo -n "已删除：$delete_count，正在删除：$name"
done

# Add newline after completion
echo ""

# Display the number of torrents deleted
echo "Number of torrents in category '$CATEGORY' to be deleted: $delete_count"

exit 0
