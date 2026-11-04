# remove_users_from_AD_group
PowerShell script to remove users from list from an AD group
# Remove-GroupUsers.ps1

A PowerShell script that removes all **user** members from a specified Active Directory group. It backs up the current membership to a CSV before making changes, supports a `-WhatIf` dry run, and reports any failures accurately.

## Features

- Verifies the group exists before doing anything
- Exports current user members to a timestamped CSV backup
- Supports `-WhatIf` and `-Confirm` via `SupportsShouldProcess`
- Per-user error handling, with a summary of any failures
- Group name passed as a parameter (no editing the script)

## Requirements

- Windows PowerShell 5.1 or PowerShell 7+ (Windows)
- The **ActiveDirectory** PowerShell module (part of RSAT: Active Directory Domain Services and Lightweight Directory Services Tools)
- An account with permission to modify membership of the target group
- Network access to a domain controller

To install RSAT on Windows 10/11:

```powershell
Add-WindowsCapability -Online -Name "Rsat.ActiveDirectory.DS-LDS.Tools~~~~0.0.1.0"
```

## Usage

```powershell
.\Remove-GroupUsers.ps1 -GroupName "Group-Name"
```

### Parameters

| Parameter    | Required | Description                                                      |
|--------------|----------|------------------------------------------------------------------|
| `-GroupName` | Yes      | Name of the AD group (name, SamAccountName, DN, GUID, or SID)    |
| `-WhatIf`    | No       | Shows what would be removed without making changes               |
| `-Confirm`   | No       | Prompts before each removal                                      |

### Examples

Preview the changes first (recommended):

```powershell
.\Remove-GroupUsers.ps1 -GroupName "Test-Group" -WhatIf
```

Run for real:

```powershell
.\Remove-GroupUsers.ps1 -GroupName "Test-Group"
```

Prompt before each removal:

```powershell
.\Remove-GroupUsers.ps1 -GroupName "Test-Group" -Confirm
```

## Output

- **Backup file:** `<SamAccountName>_members_<yyyyMMdd_HHmmss>.csv`, saved in the current working directory. It contains `SamAccountName`, `Name`, and `DistinguishedName` for each user removed.
- **Console output:** the number of users backed up, any per-user warnings, and a final summary listing any failures.

## Restoring members

To re-add users from a backup file:

```powershell
Import-Csv .\Group-Name_members_20250101_120000.csv |
    ForEach-Object { Add-ADGroupMember -Identity "Group-Name" -Members $_.SamAccountName }
```

## Limitations

- **Only direct user members are removed.** Nested groups, computers, and other object types are left in place. Remove the `objectClass` filter in the script if you want those removed too.
- **Large groups:** `Get-ADGroupMember` can fail or return incomplete results on groups with more than about 5,000 members (the AD Web Services limit). For very large groups, read the `Member` attribute with `Get-ADGroup -Properties Member` and process in batches.
- **Primary group:** users whose primary group is the target group (commonly "Domain Users") cannot be removed with `Remove-ADGroupMember`.
- **Dynamic or Protected groups:** privileged groups (e.g., Domain Admins) may be subject to AdminSDHolder protection or additional policy restrictions.
