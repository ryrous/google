# Requires:
# - A valid Google Pollen API key (stored in an environment variable) --> [System.Environment]::SetEnvironmentVariable('GOOGLE_POLLEN_API_KEY','YOUR_API_KEY')
# - The 'Invoke-WebRequest' cmdlet (comes with PowerShell)
# - Optionally, a module to parse JSON (e.g., 'ConvertFrom-Json')
function Get-PollenData {
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

  
  ############################
  Invoke-RestMethod "https://pollen.googleapis.com/v1/forecast:lookup?key=$env:GOOGLE_POLLEN_API_KEY&location.longitude=$Longitude&location.latitude=$Latitude&days=1"
  ############################
}

$Results = Get-PollenData | ConvertTo-Json -Depth 100 | ConvertFrom-Json -Depth 100 -AsHashtable


$Results.dailyInfo | ForEach-Object {
  $Date = "{0}/{1}/{2}" -f $_.date.month, $_.date.day, $_.date.year
  Write-Host "-----------------------------"
  Write-Output "Pollen Report for Date: $Date"
  Write-Host "-----------------------------"
}

$Results.dailyInfo.pollenTypeInfo | ForEach-Object {
  $Name = $_.displayName
  $pollenindexInfoName = $_.indexInfo.displayName
  $pollenindexInfoValue = $_.indexInfo.value
  $pollenindexInfoCategory = $_.indexInfo.category
  $HealthRecommendations = $_.healthRecommendations
  Write-Output "Name: $Name"
  Write-Output "Index Name: $pollenindexInfoName"
  Write-Output "Index Value: $pollenindexInfoValue"
  Write-Output "Index Category: $pollenindexInfoCategory"
  Write-Output "Health Recommendations: $HealthRecommendations"
  Write-Host "-----------------------------"
}
<#
$Results.dailyInfo.plantInfo | ForEach-Object {
  $Name = $_.displayName
  $inSeason = $_.inSeason
  $plantindexInfoName = $_.indexInfo.displayName
  $plantindexInfoValue = $_.indexInfo.value
  $plantindexInfoCategory = $_.indexInfo.category
  $plantDescriptionType = $_.plantDescription.Type
  $plantDescriptionFamily = $_.plantDescription.Family
  $plantDescriptionSeason = $_.plantDescription.Season
  Write-Output "Name: $Name"
  Write-Output "In Season: $inSeason"
  Write-Output "Index Name: $plantindexInfoName"
  Write-Output "Index Value: $plantindexInfoValue"
  Write-Output "Index Category: $plantindexInfoCategory"
  Write-Output "Plant Description Type: $plantDescriptionType"
  Write-Output "Plant Description Family: $plantDescriptionFamily"
  Write-Output "Plant Description Season: $plantDescriptionSeason"
  Write-Host "-----------------------------"
}
#>
