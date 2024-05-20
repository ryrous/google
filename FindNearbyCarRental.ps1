# Requires:
# - A valid Google Maps Geolocation API key (stored in an environment variable) --> [System.Environment]::SetEnvironmentVariable('GOOGLE_GEO_API_KEY','YOUR_API_KEY')
# - A valid Google Maps Places API key (stored in an environment variable) --> [System.Environment]::SetEnvironmentVariable('GOOGLE_PLACES_API_KEY','YOUR_API_KEY')
# - The 'Invoke-WebRequest' cmdlet (comes with PowerShell)
# - Optionally, a module to parse JSON (e.g., 'ConvertFrom-Json')
function Find-NearbyCarRental {
  # Get the current location using the Geolocation API
  $GeoKey = $env:GOOGLE_GEO_API_KEY
  $response = Invoke-RestMethod -Uri "https://www.googleapis.com/geolocation/v1/geolocate?key=$GeoKey" -ContentType "application/json" -Method Post
  # Check for successful response
  if ($response) {
      # Get the latitude and longitude
      $Latitude = [Decimal]::Round($response.location.lat, 4)
      $Longitude = [Decimal]::Round($response.location.lng, 4)
  } else {
      Write-Host "Error: Fetching coords failed."
      return $null
  }

  $Body = @{
    "includedTypes" = "car_rental"
    "maxResultCount" = 10
    "locationRestriction" = @{
      "circle" = @{
        "center" = @{
          "latitude" = $Latitude
          "longitude" = $Longitude
        }
        "radius" = 50000.0
      }
    }
  } | ConvertTo-Json -Depth 100

  $Headers = @{
    "X-Goog-FieldMask" = "*" # Return all fields
    "X-Goog-Api-Key" = $env:GOOGLE_PLACES_API_NEW_KEY
  }
  
  ############################
  Invoke-RestMethod "https://places.googleapis.com/v1/places:searchNearby" -ContentType "application/json" -Headers $Headers -Body $Body -Method Post
  ############################
}

Write-Host "-----------------------------"
Write-Host "Finding Nearby Car Rentals..."
Write-Host "-----------------------------"
$Results = Find-NearbyCarRental | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100 -AsHashtable
$Results.places | ForEach-Object {
  $Name = $_.displayName.text
  $Type = $_.primaryTypeDisplayName.text
  $Address = $_.formattedAddress
  $Phone = $_.internationalPhoneNumber
  $Rating = $_.rating
  $TotalRatings = $_.userRatingCount
  $Website = $_.websiteUri
  $GoogleMaps = $_.googleMapsUri
  $BusinessStatus = $_.businessStatus
  Write-Host "-----------------------------"
  Write-Host "Name: $Name"
  Write-Host "Type: $Type"
  Write-Host "Address: $Address"
  Write-Host "Phone: $Phone"
  Write-Host "Rating: $Rating"
  Write-Host "Total Ratings: $TotalRatings"
  Write-Host "Website: $Website"
  Write-Host "Google Maps: $GoogleMaps"
  Write-Host "Business Status: $BusinessStatus"
  Write-Host "-----------------------------"
}
