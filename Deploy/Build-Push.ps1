Param(
    [parameter(Mandatory=$true)][string]$resourceGroup,
    [parameter(Mandatory=$true)][string]$acrName,
    [parameter(Mandatory=$false)][bool]$dockerBuild=$true,
    [parameter(Mandatory=$false)][bool]$dockerPush=$true,
    [parameter(Mandatory=$false)][string]$dockerTag="latest",
    [parameter(Mandatory=$false)][bool]$isWindowsMachine=$false
)

$sourceFolder=$(Join-Path -Path .. -ChildPath Source)

Write-Host "---------------------------------------------------" -ForegroundColor Yellow
Write-Host "Getting info from ACR $resourceGroup/$acrName" -ForegroundColor Yellow
Write-Host "---------------------------------------------------" -ForegroundColor Yellow
$acrLoginServer=$(az acr show -g $resourceGroup -n $acrName -o json | ConvertFrom-Json).loginServer
$acrCredentials=$(az acr credential show -g $resourceGroup -n $acrName -o json | ConvertFrom-Json)
$acrPwd=$acrCredentials.passwords[0].value
$acrUser=$acrCredentials.username
$dockerComposeFile= If ($isWindowsMachine) {"docker-compose-win.yml"} Else {"docker-compose.yml"}

if ($dockerBuild) {
    Write-Host "---------------------------------------------------" -ForegroundColor Yellow
    Write-Host "Using docker compose to build & tag images." -ForegroundColor Yellow
    Write-Host "Images will be named as $acrLoginServer/imageName:$dockerTag" -ForegroundColor Yellow
    Write-Host "---------------------------------------------------" -ForegroundColor Yellow

    Push-Location $sourceFolder
    $env:TAG=$dockerTag
    $env:REGISTRY=$acrLoginServer 
    docker-compose -f $dockerComposeFile build
    Pop-Location
}

if ($dockerPush) {
    Write-Host "---------------------------------------------------" -ForegroundColor Yellow
    Write-Host "Pushing images to $acrLoginServer" -ForegroundColor Yellow
    Write-Host "---------------------------------------------------" -ForegroundColor Yellow

    Push-Location $sourceFolder
    docker login -p $acrPwd -u $acrUser $acrLoginServer
    $env:TAG=$dockerTag
    $env:REGISTRY=$acrLoginServer 
    docker-compose -f $dockerComposeFile push
    Pop-Location
}
