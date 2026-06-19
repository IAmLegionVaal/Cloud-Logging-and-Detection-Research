# Cloud Logging and Detection Research

A defensive research repository for assessing cloud log coverage, retention, normalization, and detection readiness.

## Research areas

- Identity, administrative, data-access, and network logs
- Retention and archive coverage
- Centralization and normalization status
- Detection use-case mapping
- Ownership and operational readiness
- Logging gaps and prioritization

## Main tool

```powershell
powershell.exe -ExecutionPolicy Bypass -File .\Cloud_Logging_and_Detection_Research.ps1 -InputCsv .\research\cloud-log-sources.csv
```

## Required CSV columns

`Platform`, `LogSource`, `Category`, `Enabled`, `Centralized`, `Normalized`, `RetentionDays`, `Owner`, `DetectionUseCases`, `Notes`

## Safety

Assessment and documentation only. No cloud logging or retention settings are changed.
