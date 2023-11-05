#!/bin/bash
# This script downloads the Bing image of the day and sets it as the desktop wallpaper for Gnome
# Requires: jq curl wget

#######################################################################################################################
##### CONFIGURABLE SETTINGS - ADJUST AS NEEDED
#
# where the images are stored when downloaded
IMG_FOLDER_PATH="/home/$USER/Pictures/BingWallpaper/"
#
# market code to use - see https://learn.microsoft.com/en-us/bing/search-apis/bing-image-search/reference/market-codes
MKT="en-CA"
#######################################################################################################################

# create image directory if it doesn't exist
mkdir -p $IMG_FOLDER_PATH

# get the json information
URL='http://www.bing.com/HPImageArchive.aspx?format=js&idx=0&n=1&mkt=$MKT'
while ! ping -c 1 bing.com > /dev/null; do sleep 1; done
JSON=$(curl -s $URL)

# parse the JSON
IMG_ADDRESS="http://www.bing.com$(echo $JSON | jq '.images[0].url' | sed -e 's/^"//'  -e 's/"$//')"
START_DATE=$(echo "$JSON" | jq '.images[0].startdate' | sed -e 's/^"//'  -e 's/"$//')
IMG_NAME=$(echo "$JSON" | jq '.images[0].urlbase' | sed 's/.*OHR.//g' | sed -e 's/^"//'  -e 's/"$//')
IMG_COPYRIGHT=$(echo "$JSON" | jq '.images[0].copyright' | sed -e 's/^"//'  -e 's/"$//')

# create the file name and path
IMG_FILE_ADDRESS="$IMG_FOLDER_PATH$START_DATE-$IMG_NAME.jpg"

# if image doesn't exist, get it, set the wallpaper, and notify the user
if [ ! -e "$IMG_FILE_ADDRESS" ]; then
    wget -O $IMG_FILE_ADDRESS $IMG_ADDRESS
    gsettings set org.gnome.desktop.background picture-uri "file://$IMG_FILE_ADDRESS"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$IMG_FILE_ADDRESS"
    
    # send the notification (reuse notification bubble if it exists)
    NOTIF=$(cat /tmp/.bingBG-notif)
    [[ -z $NOTIF ]] && NOTIF=1
    # https://gist.github.com/kiosion/40d71f765cbad0be95ae308418b83c3a
    gdbus call \
        --session \
        --dest org.freedesktop.Notifications \
        --object-path /org/freedesktop/Notifications \
        --method org.freedesktop.Notifications.Notify \
        -- \
        "identifier" \
        "$(echo $NOTIF)" \
        "preferences-desktop-wallpaper" \
        "New Background" \
        "$(echo $IMG_COPYRIGHT)" \
        "[]" \
        "{}" \
        "20000" \
    | sed 's/[^ ]* //; s/,.//' > /tmp/.bingBG-notif
fi

exit 0

