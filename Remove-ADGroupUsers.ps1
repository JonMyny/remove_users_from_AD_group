[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)]
    [string]$GroupName
)

Import-Module ActiveDirectory -ErrorAction Stop

# Verify the group exists before doing anything
try {
    $Group = Get-ADGroup -Identity $GroupName -ErrorAction Stop
}
catch {
    Write-Error "Group '$GroupName' not found: $_"
    return
}

# Get direct user members
$Users = Get-ADGroupMember -Identity $Group | Where-Object { $_.objectClass -eq 'user' }

if (-not $Users) {
    Write-Output "No user members found in '$GroupName'."
    return
}

# Back up membership before changing anything
$BackupPath = ".\$($Group.SamAccountName)_members_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
$Users | Select-Object SamAccountName, Name, DistinguishedName |
    Export-Csv -Path $BackupPath -NoTypeInformation
Write-Output "Backed up $($Users.Count) members to $BackupPath"

# Remove users, tracking failures
$Failed = @()
foreach ($User in $Users) {
    if ($PSCmdlet.ShouldProcess($User.SamAccountName, "Remove from $GroupName")) {
        try {
            Remove-ADGroupMember -Identity $Group -Members $User -Confirm:$false -ErrorAction Stop
        }
        catch {
            $Failed += $User.SamAccountName
            Write-Warning "Failed to remove $($User.SamAccountName): $_"
        }
    }
}

if ($Failed) {
    Write-Output "Completed with $($Failed.Count) failure(s): $($Failed -join ', ')"
}
else {
    Write-Output "Removed $($Users.Count) user(s) from '$GroupName'."
}
