<#
.SYNOPSIS
  将带尾部注释的 CONFIG_ 行拆成“注释在上，代码在下”两行，
  支持“# CONFIG_… is not set”格式，去掉所有行尾空白，并使用 UTF-8 编码。

.EXAMPLE
  .\fix-config.ps1 -InputPath default.config -OutputPath default.config.fixed
#>

param(
  [string] $InputPath  = "default.config",
  [string] $OutputPath = "default.config.fixed"
)

# 强制控制台输出 UTF-8
[Console]::OutputEncoding = [Text.UTF8Encoding]::new()

# 这个正则能捕获：
#  - Group 1: 以 “CONFIG_…=y” 或 “# CONFIG_… is not set” 开头的代码部分（不含尾空格）
#  - Group 2: 紧跟其后的注释文本
$pattern = '^(#?\s*CONFIG_[^#\s].*?)\s*#\s*(.*)$'

Get-Content $InputPath -Encoding UTF8 | ForEach-Object {
    $line = $_
    if ($line -match $pattern) {
        # 输出注释行（TrimEnd 去掉可能的尾部空格）
        ("# " + $Matches[2]).TrimEnd()
        # 输出原始 CONFIG 行，也 TrimEnd
        $Matches[1].TrimEnd()
    }
    else {
        # 其它行仅去掉尾部空格
        $line.TrimEnd()
    }
} | Out-File -FilePath $OutputPath -Encoding UTF8

Write-Host "已生成：$OutputPath（注释拆分完毕，行尾空白已清理）"
