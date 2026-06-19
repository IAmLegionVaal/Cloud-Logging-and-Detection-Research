#requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][string]$InputCsv,[string]$OutputPath)
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
if([string]::IsNullOrWhiteSpace($OutputPath)){$OutputPath=Join-Path ([Environment]::GetFolderPath('Desktop')) 'Cloud_Logging_Detection_Research'}
New-Item -Path $OutputPath -ItemType Directory -Force|Out-Null
if(-not(Test-Path $InputCsv)){Write-Error 'Input CSV not found.';return}
$rows=Import-Csv $InputCsv|ForEach-Object{
 $enabled=$_.Enabled -match 'Yes|True'
 $centralized=$_.Centralized -match 'Yes|True'
 $normalized=$_.Normalized -match 'Yes|True'
 $retention=0;[void][int]::TryParse($_.RetentionDays,[ref]$retention)
 $score=0;if($enabled){$score+=35};if($centralized){$score+=25};if($normalized){$score+=20};if($retention -ge 90){$score+=20}elseif($retention -ge 30){$score+=10}
 [PSCustomObject]@{Platform=$_.Platform;LogSource=$_.LogSource;Category=$_.Category;Enabled=$enabled;Centralized=$centralized;Normalized=$normalized;RetentionDays=$retention;Owner=$_.Owner;DetectionUseCases=$_.DetectionUseCases;ReadinessScore=$score;Status=$(if($score -ge 80){'Strong'}elseif($score -ge 50){'Developing'}else{'Gap'});Notes=$_.Notes}
}
$byPlatform=$rows|Group-Object Platform|ForEach-Object{[PSCustomObject]@{Platform=$_.Name;Sources=$_.Count;Enabled=@($_.Group|Where-Object Enabled).Count;Centralized=@($_.Group|Where-Object Centralized).Count;AverageScore=[math]::Round((($_.Group.ReadinessScore|Measure-Object -Average).Average),1)}}
$byCategory=$rows|Group-Object Category|ForEach-Object{[PSCustomObject]@{Category=$_.Name;Sources=$_.Count;AverageScore=[math]::Round((($_.Group.ReadinessScore|Measure-Object -Average).Average),1)}}
$gaps=$rows|Where-Object Status -ne 'Strong'|Select-Object Platform,LogSource,Category,Enabled,Centralized,Normalized,RetentionDays,Owner,ReadinessScore,Status
$summary=[PSCustomObject]@{Sources=@($rows).Count;Strong=@($rows|Where-Object Status -eq 'Strong').Count;Developing=@($rows|Where-Object Status -eq 'Developing').Count;Gaps=@($rows|Where-Object Status -eq 'Gap').Count;AverageScore=[math]::Round((($rows.ReadinessScore|Measure-Object -Average).Average),1);Generated=Get-Date}
$rows|Export-Csv (Join-Path $OutputPath "cloud_log_inventory_$stamp.csv") -NoTypeInformation -Encoding UTF8
$byPlatform|Export-Csv (Join-Path $OutputPath "platform_summary_$stamp.csv") -NoTypeInformation -Encoding UTF8
$byCategory|Export-Csv (Join-Path $OutputPath "category_summary_$stamp.csv") -NoTypeInformation -Encoding UTF8
$gaps|Export-Csv (Join-Path $OutputPath "logging_gaps_$stamp.csv") -NoTypeInformation -Encoding UTF8
@{Summary=$summary;Inventory=$rows;PlatformSummary=$byPlatform;CategorySummary=$byCategory;Gaps=$gaps}|ConvertTo-Json -Depth 8|Set-Content (Join-Path $OutputPath "cloud_logging_research_$stamp.json") -Encoding UTF8
$html="<h1>Cloud Logging and Detection Research</h1><p>Generated $(Get-Date)</p><h2>Summary</h2>$(@($summary)|ConvertTo-Html -Fragment)<h2>Platform Summary</h2>$($byPlatform|ConvertTo-Html -Fragment)<h2>Logging Gaps</h2>$($gaps|ConvertTo-Html -Fragment)"
$html|ConvertTo-Html -Title 'Cloud Logging and Detection Research'|Set-Content (Join-Path $OutputPath "cloud_logging_research_$stamp.html") -Encoding UTF8
$summary|Format-List
Write-Host "Reports saved to: $OutputPath" -ForegroundColor Green
