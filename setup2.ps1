<#
================================================================================
スクリプト名：setup2.ps1
概要　　　　：Firefox関連ファイルを所定の場所へコピーする
作成　　　　：2026/11/20 三井田 隆

本スクリプトは親スクリプト（setup1.ps1）から呼び出される。
関連ファイルは親スクリプトによってローカルTEMPへコピー済み。
親スクリプトの管理者権限を引き継いで実行する。
================================================================================
#>

#-------------------------【 パラメータ 】-------------------------#

param(
    [string]$TMP_PATH
)

#-------------------------【 メイン処理 】-------------------------#

# 画面の背景色設定
$Host.UI.RawUI.BackgroundColor = "White"
$Host.UI.RawUI.ForegroundColor = "Black"
Clear-Host

Write-Host ""
Write-Host " ----------------------------------------"
Write-Host " Firefox 初期設定"
Write-Host " ----------------------------------------"
Write-Host ""

# TEMPパス確認
if ([string]::IsNullOrWhiteSpace($TMP_PATH)) {
    Write-Host "TMP_PATHが指定されていません。"
    Read-Host "Enterで終了"
    exit 1
}

$sourceDir = Join-Path $TMP_PATH "tmpGSS"

if (-not (Test-Path -LiteralPath $sourceDir -PathType Container)) {
    Write-Host "コピー元フォルダが見つかりません：$sourceDir"
    Read-Host "Enterで終了"
    exit 1
}

#Write-Host "受け取ったTMP_PATH：$TMP_PATH"

#-------------------------【 管理者権限確認 】-------------------------#

$identity = [Security.Principal.WindowsIdentity]::GetCurrent()

$principal = New-Object System.Security.Principal.WindowsPrincipal -ArgumentList $identity

$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

#Write-Host "ユーザー：$($identity.Name)"
#Write-Host "管理者権限：$isAdmin"

if (-not $isAdmin) {
    Write-Host "管理者権限で実行されていません。"
    Read-Host "Enterで終了"
    exit 1
}

#-------------------------【 コピー元ファイル確認 】-------------------------#

$files = @(
    "policies.json"
    "autoconfig.js"
    "autoconfig.cfg"
    "新工事原価管理システム.lnk"
)

foreach ($file in $files) {
    $path = Join-Path $sourceDir $file

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Write-Host "コピー元ファイルがありません：$path"
        Read-Host "Enterで終了"
        exit 1
    }
}

#-------------------------【 初期ショートカット削除 】-------------------------#

$oldShortcut = "C:\Users\Public\Desktop\新工事原価管理システム.lnk"

if (Test-Path -LiteralPath $oldShortcut) {
    Remove-Item -LiteralPath $oldShortcut -Force
    #Write-Host "初期ショートカットを削除しました。"
}

#-------------------------【 フォルダ作成 】-------------------------#

$firefoxDir = "C:\Program Files\Mozilla Firefox02"

$distributionDir = Join-Path $firefoxDir "distribution"
$prefDir = Join-Path $firefoxDir "defaults\pref"

New-Item -Path $distributionDir -ItemType Directory -Force | Out-Null
New-Item -Path $prefDir -ItemType Directory -Force | Out-Null

#-------------------------【 ファイルコピー 】-------------------------#

Write-Host ""
Write-Host "Firefox関連ファイルをコピーしています..."
Write-Host ""

# policies.json
Copy-Item `
    -LiteralPath (Join-Path $sourceDir "policies.json") `
    -Destination $distributionDir `
    -Force

# autoconfig.js
Copy-Item `
    -LiteralPath (Join-Path $sourceDir "autoconfig.js") `
    -Destination $prefDir `
    -Force

# autoconfig.cfg
Copy-Item `
    -LiteralPath (Join-Path $sourceDir "autoconfig.cfg") `
    -Destination $firefoxDir `
    -Force

# 新工事原価管理システム.lnk
Copy-Item `
    -LiteralPath (Join-Path $sourceDir "新工事原価管理システム.lnk") `
    -Destination "C:\Users\Public\Desktop" `
    -Force

#-------------------------【 コピー結果確認 】-------------------------#

$checkFiles = @(
    (Join-Path $distributionDir "policies.json")
    (Join-Path $prefDir "autoconfig.js")
    (Join-Path $firefoxDir "autoconfig.cfg")
    "C:\Users\Public\Desktop\新工事原価管理システム.lnk"
)

$allSuccess = $true

foreach ($path in $checkFiles) {

    if (Test-Path -LiteralPath $path -PathType Leaf) {
        Write-Host "コピー成功：$path"
    }
    else {
        Write-Host "コピー失敗：$path"
        $allSuccess = $false
    } 
}

Write-Host ""
#pause

#-------------------------【 既存フォルダ削除 】-------------------------#
# 既存フォルダ削除
$deltmp = Join-Path $TMP_PATH "\tmpGSSSetup"
$deltmpSV = Join-Path $TMP_PATH "\2"

if (Test-Path -LiteralPath $deltmp) {
    Remove-Item -LiteralPath $deltmp -Recurse -Force
}
if (Test-Path -LiteralPath $deltmpSV) {
    Remove-Item -LiteralPath $deltmpSV -Recurse -Force
}

#-------------------------【 終了 】-------------------------#

Write-Host ""

if ($allSuccess) {
    Write-Host "Firefox初期設定が完了しました。"
}
else {
    Write-Host "Firefox初期設定でエラーが発生しました。"
}

Write-Host ""

pause

if ($allSuccess) {
    exit 0
}
else {
    exit 1
}