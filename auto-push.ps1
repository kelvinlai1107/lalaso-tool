# ============================================================
#  Boter 排程工具 — 自動 Git Push 監視腳本
#  監視 boter_schedule/index.html，變更後自動 commit + push
# ============================================================

$RepoRoot  = $PSScriptRoot
$WatchFile = Join-Path $RepoRoot "boter_schedule\index.html"
$WatchDir  = Join-Path $RepoRoot "boter_schedule"
$DebounceMs = 4000   # 變更後等待 4 秒再推送（避免連續寫入重複觸發）

Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Boter 自動推送已啟動" -ForegroundColor Cyan
Write-Host "  監視：$WatchFile" -ForegroundColor Gray
Write-Host "  每次儲存後約 4 秒自動 commit + push" -ForegroundColor Gray
Write-Host "  按 Ctrl+C 停止" -ForegroundColor Gray
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path   = $WatchDir
$watcher.Filter = "index.html"
$watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite
$watcher.EnableRaisingEvents = $true

$timer = New-Object System.Timers.Timer
$timer.Interval  = $DebounceMs
$timer.AutoReset = $false

$timerAction = {
    $timer.Stop()
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] 偵測到變更，開始推送…" -ForegroundColor Yellow

    Set-Location $RepoRoot

    # git add
    & git add boter_schedule/index.html 2>&1 | Out-Null

    # 確認有東西要 commit
    $status = & git status --porcelain boter_schedule/index.html
    if (-not $status) {
        Write-Host "  → 無新變更，略過" -ForegroundColor Gray
        return
    }

    # git commit
    $msg = "auto: update boter_schedule $(Get-Date -Format 'MM/dd HH:mm')"
    $commitOut = & git commit -m $msg 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ✗ commit 失敗：$commitOut" -ForegroundColor Red
        return
    }

    # git push
    $pushOut = & git push 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ 已推送到 GitHub Pages" -ForegroundColor Green
    } else {
        Write-Host "  ✗ push 失敗：$pushOut" -ForegroundColor Red
    }
    Write-Host ""
}

# 每次檔案變更，重設計時器（debounce）
Register-ObjectEvent $watcher Changed -Action {
    $timer.Stop()
    $timer.Start()
} | Out-Null

Register-ObjectEvent $timer Elapsed -Action $timerAction | Out-Null

# 保持腳本執行直到使用者按 Ctrl+C
try {
    while ($true) { Start-Sleep -Seconds 1 }
} finally {
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    $timer.Dispose()
    Write-Host "`n自動推送已停止。" -ForegroundColor Cyan
}
