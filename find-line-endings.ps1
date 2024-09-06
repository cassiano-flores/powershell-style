function Find-LF {
  Get-ChildItem -Recurse -File | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "`n" -and $content -notmatch "`r`n") {
      Write-Output $_.FullName
    }
  }
}

function Find-CRLF {
  Get-ChildItem -Recurse -File | ForEach-Object {
    if ((Get-Content $_.FullName -Raw) -match "`r`n") {
      Write-Output $_.FullName
    }
  }
}
