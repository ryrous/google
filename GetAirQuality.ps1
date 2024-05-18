# Requires:
# - A valid Google Air Quality API key (stored in an environment variable) --> [System.Environment]::SetEnvironmentVariable('GOOGLE_AIR_QUALITY_API_KEY','YOUR_API_KEY')
# - The 'Invoke-WebRequest' cmdlet (comes with PowerShell)
# - Optionally, a module to parse JSON (e.g., 'ConvertFrom-Json')
function Get-AirQualityData {
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
    "location"= @{
      "latitude" = $Latitude 
      "longitude" = $Longitude
    }
  } | ConvertTo-Json -Depth 100
  
  $Headers = @{
    "X-Goog-FieldMask" = "*" # Return all fields
    "X-Goog-Api-Key" = $env:GOOGLE_AIR_QUALITY_API_KEY
  }
  
  ############################
  Invoke-RestMethod "https://airquality.googleapis.com/v1/currentConditions:lookup" -ContentType "application/json" -Headers $Headers -Body $Body -Method Post
  ############################
}

$Results = Get-AirQualityData | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100 -AsHashtable
$Results | ForEach-Object {
  $Date = $_.dateTime
  $Name = $_.indexes.displayName
  $AQI = $_.indexes.aqiDisplay
  $Category = $_.indexes.category
  $Pollutant = $_.indexes.dominantPollutant
  Write-Host "-----------------------------"
  Write-Output "Air Quality Report for Date: $Date"
  Write-Host "-----------------------------"
  Write-Output "Name: $Name"
  Write-Output "AQI: $AQI"
  Write-Output "Category: $Category"
  Write-Output "Dominant Pollutant: $Pollutant"
  Write-Host "-----------------------------"
}
