param(
  [string]$Region = 'us-west-2',
  [string]$StackName = ''
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($StackName)) {
  $namePrefix = if ($env:USERNAME) { $env:USERNAME } else { 'user' }
  $namePrefix = ($namePrefix.ToLower() -replace '[^a-z0-9-]', '-').Trim('-')
  if ([string]::IsNullOrWhiteSpace($namePrefix)) {
    $namePrefix = 'user'
  }
  if ($namePrefix -notmatch '^[a-z]') {
    $namePrefix = "user-$namePrefix"
  }
  if ($namePrefix.Length -gt 20) {
    $namePrefix = $namePrefix.Substring(0, 20).Trim('-')
  }
  $StackName = "$namePrefix-byol-node-express"
}

$accountId = aws sts get-caller-identity --query Account --output text
$artifactBucket = "$StackName-artifacts-$accountId-$Region".ToLower()

$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
aws s3api head-bucket --bucket $artifactBucket --region $Region 2>$null
$bucketExists = $LASTEXITCODE -eq 0
$ErrorActionPreference = $previousErrorActionPreference

if (-not $bucketExists) {
  if ($Region -eq 'us-east-1') {
    aws s3api create-bucket `
      --bucket $artifactBucket `
      --region $Region | Out-Null
  } else {
    aws s3api create-bucket `
      --bucket $artifactBucket `
      --region $Region `
      --create-bucket-configuration LocationConstraint=$Region | Out-Null
  }
}

aws cloudformation package `
  --template-file template.yaml `
  --s3-bucket $artifactBucket `
  --output-template-file packaged.yaml

aws cloudformation deploy `
  --template-file packaged.yaml `
  --stack-name $StackName `
  --region $Region `
  --capabilities CAPABILITY_IAM `
  --no-fail-on-empty-changeset

$apiUrl = aws cloudformation describe-stacks `
  --stack-name $StackName `
  --region $Region `
  --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" `
  --output text

Write-Host "Deployed: $apiUrl"
