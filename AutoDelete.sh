#!/bin/bash

# Set the HOST variable
HOST="http://192.168.2.10:8080"

# Define API URLs
FETCH_API_URL="$HOST/api/v2/torrents/info"
TRACKERS_API_URL="$HOST/api/v2/torrents/trackers"
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

# Parse and display the JSON response using jq, filtered by provided category
filtered_response=$(echo "$response" | jq --arg category "$CATEGORY" '[.[] | select(.category == $category)]')

# Count the number of matching torrents
matching_count=$(echo "$filtered_response" | jq 'length')

# Check if there are any torrents in the filtered response
if [ "$matching_count" -eq 0 ]; then
  echo "No torrents found with category '$CATEGORY'"
  exit 0
fi

# Extract the hashes and names of matching torrents
torrents=$(echo "$filtered_response" | jq -r '.[] | "\(.hash) \(.name)"')

# Initialize an array to store torrents to be deleted
torrents_to_delete=()

# Check each torrent's trackers for the specific message
while read -r hash name; do
  trackers_response=$(curl -s "$TRACKERS_API_URL?hash=$hash")

  # Check if the request was successful
  if [ $? -ne 0 ]; then
    continue
  fi

  # Check if any tracker has the "torrent not registered with this tracker" message
  if echo "$trackers_response" | jq -e '.[] | select(.msg == "torrent not registered with this tracker")' > /dev/null; then
    torrents_to_delete+=("$hash $name")
  fi
done <<< "$torrents"

# Count the number of torrents to be deleted
delete_count=${#torrents_to_delete[@]}

# Display the number of torrents to be deleted
echo "Number of torrents to be deleted: $delete_count"

# Check if there are any torrents to be deleted
if [ "$delete_count" -eq 0 ]; then
  echo "No torrents found with the message 'torrent not registered with this tracker'"
  exit 0
fi

# Display the names of torrents to be deleted
echo "The following torrents are eligible for deletion:"
for torrent in "${torrents_to_delete[@]}"; do
  echo "Name: ${torrent#* }"
done

# Prompt user for confirmation
read -p "Do you want to delete these torrents? (y/n): " confirmation

# Check user's input
if [ "$confirmation" != "y" ]; then
  echo "Deletion cancelled by user."
  exit 0
fi

# Initialize delete count
delete_count=0

# Loop through each torrent to be deleted
for torrent in "${torrents_to_delete[@]}"; do
  hash="${torrent%% *}"
  name="${torrent#* }"

  # Send POST request to delete the torrent
  delete_response=$(curl -s -X POST "$DELETE_API_URL" --data-urlencode "hashes=$hash" --data-urlencode "deleteFiles=true")

  # Check if the delete request was successful
  if [ $? -ne 0 ]; then
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

exit 0
