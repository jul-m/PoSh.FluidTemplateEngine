$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $PSScriptRoot '../out/publish/PoSh.FluidTemplateEngine/PoSh.FluidTemplateEngine.psd1'
Import-Module $modulePath -Force

Set-FluidModuleConfig -Reset

# ──────────────────────────────────────
# Custom Tags
# ──────────────────────────────────────

Write-Host "== Custom Tags ==" -ForegroundColor Cyan

# Empty tag: no parameter
Register-LiquidTag -Name 'timestamp' -Type Empty -ScriptBlock { (Get-Date).ToString('yyyy-MM-dd') }
Format-LiquidString -Source 'Rendered on {% timestamp %}' -Model @{} | Write-Host

# Identifier tag: receives an identifier
Register-LiquidTag -Name 'hello' -Type Identifier -ScriptBlock {
    param($identifier)
    "Hello $identifier!"
}
Format-LiquidString -Source '{% hello world %}' -Model @{} | Write-Host

# Expression tag: receives the evaluated expression
Register-LiquidTag -Name 'echo' -Type Expression -ScriptBlock {
    param($value)
    ">> $value <<"
}
Format-LiquidString -Source "{% echo 'test' | upcase %}" -Model @{} | Write-Host

# ──────────────────────────────────────
# Custom Blocks
# ──────────────────────────────────────

Write-Host "`n== Custom Blocks ==" -ForegroundColor Cyan

# Empty block: wraps content
Register-LiquidBlock -Name 'card' -Type Empty -ScriptBlock {
    param($body)
    "<div class='card'>$body</div>"
}
Format-LiquidString -Source '{% card %}Important content{% endcard %}' -Model @{} | Write-Host

# Identifier block: wraps with a named HTML tag
Register-LiquidBlock -Name 'wrap' -Type Identifier -ScriptBlock {
    param($identifier, $body)
    "<$identifier>$body</$identifier>"
}
Format-LiquidString -Source '{% wrap section %}Article text{% endwrap %}' -Model @{} | Write-Host

# Expression block: repeats content N times
Register-LiquidBlock -Name 'repeat' -Type Expression -ScriptBlock {
    param($value, $body)
    $body * [int]$value
}
Format-LiquidString -Source '{% repeat 3 %}Go! {% endrepeat %}' -Model @{} | Write-Host

# ──────────────────────────────────────
# Custom Operators
# ──────────────────────────────────────

Write-Host "`n== Custom Operators ==" -ForegroundColor Cyan

Register-LiquidOperator -Name 'xor' -ScriptBlock {
    param($left, $right)
    [bool]$left -xor [bool]$right
}
Format-LiquidString -Source '{% if true xor false %}XOR=true{% else %}XOR=false{% endif %}' -Model @{} | Write-Host
Format-LiquidString -Source '{% if true xor true %}XOR=true{% else %}XOR=false{% endif %}' -Model @{} | Write-Host
