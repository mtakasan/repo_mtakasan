<#
================================================================================
スクリプト名：setup1.ps1
概要　　　　：Firefoxのインストール、および初期設定を行う。
作成　　　　：2026/11/20 三井田 隆
================================================================================
#>

#-------------------------【 パラメータ 】-------------------------#

param(
    [string]$SETUP_ROOT
)

#-------------------------【 関数の定義 】-------------------------#

# ファイルがコピーできているか確認する関数
function checkFile([String]$cp_path, [String]$disp_fname) {

    if (Test-Path -LiteralPath $cp_path -PathType Leaf) {
        Write-Host ($disp_fname + "　コピー成功")
    }
    else {
        Write-Host ($disp_fname + "　コピー失敗！")
    }
}

# DOSコマンド「pause」の代替関数
function pause() {
    Write-Host " ▽続行するには何かキーを押して下さい..."
    Write-Host ""
    [Console]::ReadKey($true) | Out-Null
}

#-------------------------【 メイン処理 】-------------------------#

#setup1.ps1が配置されているフォルダを取得
$SETUP_ROOT = $PSScriptRoot

# ショートカットから渡されたsetupフォルダ
if ([string]::IsNullOrWhiteSpace($SETUP_ROOT)) {
    Write-Host "setupフォルダの引数が指定されていません。"
    Read-Host "Enterで終了"
    exit 1
}

# フォルダの存在確認
if (-not (Test-Path -LiteralPath $SETUP_ROOT -PathType Container)) {
    Write-Host "setupフォルダが見つかりません：$SETUP_ROOT"
    Read-Host "Enterで終了"
    exit 1
}

# パスを正規化
$SETUP_ROOT = (Get-Item -LiteralPath $SETUP_ROOT).FullName

# OSアーキテクチャを判別
if ([Environment]::Is64BitOperatingSystem) {
    $BIT = "64"
}
else {
    $BIT = "32"
}

# 管理者権限の確認
$identity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object System.Security.Principal.WindowsPrincipal -ArgumentList $identity

$isAdmin = $principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

#-------------------------【 管理者権限への昇格 】-------------------------#

if (-not $isAdmin) {

#   Write-Host "管理者権限で再起動します。"
    Write-Host "セットアップファイルをローカルへコピーしています..."

    # ローカル作業フォルダ
    $stageRoot = Join-Path $env:TEMP "tmpGSSSetup"
    $stageRootSV = Join-Path $env:TEMP "2"

    # 既存フォルダ削除
    if (Test-Path -LiteralPath $stageRoot) {
        Remove-Item -LiteralPath $stageRoot -Recurse -Force
    }
    # 既存フォルダ削除
    if (Test-Path -LiteralPath $stageRootSV) {
        Remove-Item -LiteralPath $stageRootSV -Recurse -Force
    }

    # ローカル作業フォルダ作成
    New-Item -Path $stageRoot -ItemType Directory -Force | Out-Null

    # setupフォルダ一式をローカルへコピー
    $ErrorActionPreference = "Stop"
    
    Copy-Item -Path (Join-Path $SETUP_ROOT "*") `
        -Destination $stageRoot `
        -Recurse `
        -Force

    # コピー結果確認
    $localScript = Join-Path $stageRoot "setup1.ps1"

    if (-not (Test-Path -LiteralPath $localScript -PathType Leaf)) {
        Write-Host "setup1.ps1のコピーに失敗しました。"
        Read-Host "Enterで終了"
        exit 1
    }

    # 管理者権限で再起動
    $argList = "-NoProfile -ExecutionPolicy Bypass -File `"$localScript`" `"$stageRoot`""

    Start-Process powershell.exe `
        -Verb RunAs `
        -ArgumentList $argList

    exit
}

#-------------------------【 管理者権限での処理 】-------------------------#

#Write-Host "管理者権限で実行中"
#Write-Host "セットアップフォルダ：$SETUP_ROOT"

# Firefoxインストーラーのパス
$INSTALL_EXE = Join-Path $SETUP_ROOT "Firefox\$($BIT)bit\Firefox Setup 160.0.1.exe"

# インストーラーの存在確認
if (-not (Test-Path -LiteralPath $INSTALL_EXE -PathType Leaf)) {
    Write-Host "Firefoxインストーラーが見つかりません。"
    Write-Host $INSTALL_EXE
    Read-Host "Enterで終了"
    exit 1
}

#-------------------------【 画面の挙動対策 】-------------------------#

#対策１
Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WindowControl {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll")]
    public static extern bool IsIconic(IntPtr hWnd);
}
"@

$hwnd = [WindowControl]::GetConsoleWindow()

# 最小化状態なら復元
if ([WindowControl]::IsIconic($hwnd)) {
    [WindowControl]::ShowWindow($hwnd, 9) | Out-Null
}

# 画面の背景色設定
$Host.UI.RawUI.BackgroundColor = "White"
$Host.UI.RawUI.ForegroundColor = "Black"
Clear-Host

Start-Sleep -Milliseconds 300

#-------------------------【 インストール開始 】-------------------------#

Write-Host ""
Write-Host " ----------------------------------------"
Write-Host " 工事原価管理システム"
Write-Host " Firefox インストール (Version 160.0.1)"
Write-Host ""
Write-Host "                             2026.12 GSS"
Write-Host " ----------------------------------------"
Write-Host ""

Write-Host " FireFox(Version 160.0.1)をインストールします"
Write-Host ""

#Write-Host "インストーラー：$INSTALL_EXE"

pause

Write-Host " インストール中です..."
Write-Host ""

# インストール先
$INSTALL_DIR = "C:\Program Files\Mozilla Firefox02"

# Firefoxのインストール
$installArgs = "/S /D=$INSTALL_DIR"

$process = Start-Process -FilePath $INSTALL_EXE `
    -ArgumentList $installArgs `
    -Wait `
    -PassThru

if ($process.ExitCode -ne 0) {
    Write-Host "Firefoxのインストールでエラーが発生しました。"
    Write-Host "終了コード：$($process.ExitCode)"
    Read-Host "Enterで終了"
    exit 1
}

Write-Host "Firefoxのインストールが完了しました。"
Write-Host ""

#-------------------------【 setup2.ps1の準備 】-------------------------#

$tmpGSS = Join-Path $env:TEMP "tmpGSS"

# 一時フォルダ削除
if (Test-Path -LiteralPath $tmpGSS) {
    Remove-Item -LiteralPath $tmpGSS -Recurse -Force
    Write-Host "一時フォルダ削除済"
}

# ローカル一時フォルダ作成
New-Item -Path $tmpGSS -ItemType Directory -Force | Out-Null

# setup2.ps1
$source = Join-Path $SETUP_ROOT "setup2.ps1"
Copy-Item -LiteralPath $source -Destination $tmpGSS -Force

# settings\policies.json
$source = Join-Path $SETUP_ROOT "settings\policies.json"
Copy-Item -LiteralPath $source -Destination $tmpGSS -Force

# settings\autoconfig.js
$source = Join-Path $SETUP_ROOT "settings\autoconfig.js"
Copy-Item -LiteralPath $source -Destination $tmpGSS -Force

# settings\autoconfig.cfg
$source = Join-Path $SETUP_ROOT "settings\autoconfig.cfg"
Copy-Item -LiteralPath $source -Destination $tmpGSS -Force

# settings\新工事原価管理システム.lnk
$source = Join-Path $SETUP_ROOT "settings\新工事原価管理システム.lnk"
Copy-Item -LiteralPath $source -Destination $tmpGSS -Force

#-------------------------【 setup2.ps1実行 】-------------------------#

Write-Host " Firefoxの初期設定を実行しています..."
Write-Host ""

$TMP_PATH = $env:TEMP

# setup1.ps1が管理者権限で動いているため、再昇格は不要
$process = Start-Process powershell.exe `
    -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$TMP_PATH\tmpGSS\setup2.ps1`" -TMP_PATH `"$TMP_PATH`"" `
    -Wait `
    -PassThru `
    -WindowStyle Normal

#Write-Host "setup2.ps1 終了コード：$($process.ExitCode)"

#-------------------------【 一時フォルダ削除 】-------------------------#

Remove-Item -LiteralPath $tmpGSS -Recurse -Force

#-------------------------【 コピーの成否確認 】-------------------------#

#checkFile "C:\Program Files\Mozilla Firefox02\distribution\policies.json" "policies.json"

#checkFile "C:\Program Files\Mozilla Firefox02\defaults\pref\autoconfig.js" "autoconfig.js"

#checkFile "C:\Program Files\Mozilla Firefox02\autoconfig.cfg" "autoconfig.cfg"

#checkFile "C:\Users\Public\Desktop\新工事原価管理システム.lnk" "新工事原価管理システム.lnk"

#-------------------------【 終了 】-------------------------#

Write-Host ""
Write-Host " ----------------------------------------"
Write-Host " インストールが完了しました"
Write-Host " ----------------------------------------"
Write-Host ""

pause

exit