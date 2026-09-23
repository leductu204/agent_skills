param([Parameter(ValueFromRemainingArguments = $true)][string[]]$CliArgs)

$ErrorActionPreference = 'Stop'
$Vault = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$RegistryFile = Join-Path $Vault 'registry.json'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Read-Json([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Không tìm thấy: $Path" }
    return (Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json)
}

function Write-Json([string]$Path, $Value) {
    $tmp = "$Path.tmp"
    [IO.File]::WriteAllText($tmp, ($Value | ConvertTo-Json -Depth 30) + "`n", $Utf8)
    Move-Item -LiteralPath $tmp -Destination $Path -Force
}

function Assert-Name([string]$Name) {
    if ($Name -cnotmatch '^[a-z0-9]+(?:-[a-z0-9]+)*$') {
        throw "Tên phải là kebab-case: chữ thường, số và dấu gạch ngang. Nhận được: $Name"
    }
}

function Get-Entry([string]$Name) {
    Assert-Name $Name
    $property = $Registry.skills.PSObject.Properties[$Name]
    if ($null -eq $property) { throw "Skill '$Name' chưa có trong registry." }
    return $property.Value
}

function Test-Registered([string]$Name) {
    return ($null -ne $Registry.skills.PSObject.Properties[$Name])
}

function Get-SkillPath($Entry) {
    $relative = [string]$Entry.path
    if ($relative -cnotmatch '^skills/(custom|vendor|incubator)/[a-z0-9]+(?:-[a-z0-9]+)*$') {
        throw "Path trong registry không hợp lệ: $relative"
    }
    return (Join-Path $Vault ($relative.Replace('/', [IO.Path]::DirectorySeparatorChar)))
}

function Get-Frontmatter([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw "Thiếu SKILL.md: $Path" }
    $raw = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    $match = [regex]::Match($raw, '(?s)\A---\s*\r?\n(.*?)\r?\n---(?:\r?\n|\z)')
    if (-not $match.Success) { throw "SKILL.md thiếu YAML front matter: $Path" }
    $meta = @{}
    foreach ($line in ($match.Groups[1].Value -split '\r?\n')) {
        if ($line -match '^([A-Za-z_][A-Za-z0-9_-]*):\s*(.*)$') {
            $meta[$Matches[1]] = $Matches[2].Trim().Trim('"', "'")
        }
    }
    return $meta
}

function Set-FrontmatterValue([string]$Path, [string]$Key, [string]$Value) {
    $raw = [IO.File]::ReadAllText($Path, [Text.Encoding]::UTF8)
    $pattern = "(?m)^$([regex]::Escape($Key)):\s*[^`r`n]*"
    if (-not [regex]::IsMatch($raw, $pattern)) { throw "SKILL.md thiếu trường $Key" }
    $raw = [regex]::Replace($raw, $pattern, "${Key}: $Value", 1)
    [IO.File]::WriteAllText($Path, $raw, $Utf8)
}

function Read-Source([string]$Path) {
    $result = @{}
    if (-not (Test-Path -LiteralPath $Path)) { return $result }
    foreach ($line in (Get-Content -LiteralPath $Path -Encoding UTF8)) {
        if ($line -match '^([a-z_]+):\s*(.*)$') {
            $value = $Matches[2].Trim()
            if ($value.StartsWith('"')) {
                try { $value = $value | ConvertFrom-Json } catch { }
            }
            $result[$Matches[1]] = $value
        }
    }
    return $result
}

function Write-Source([string]$Path, $Fields) {
    $keys = @('name','source','upstream_version','upstream_commit','downloaded','license','modified','local_version','review_status','based_on')
    $lines = @()
    foreach ($key in $keys) {
        if ($Fields.ContainsKey($key)) {
            $value = $Fields[$key]
            if ($value -is [bool]) { $encoded = "$value".ToLowerInvariant() }
            else { $encoded = ConvertTo-Json -InputObject ([string]$value) -Compress }
            $lines += "${key}: $encoded"
        }
    }
    [IO.File]::WriteAllText($Path, ($lines -join "`n") + "`n", $Utf8)
}

function Test-ForbiddenName([string]$Name) {
    return ($Name -match '^(?i:(\.env(?:\..*)?|credentials?(?:\..*)?|id_rsa.*|id_ed25519.*|.*\.(?:pem|key|pfx|p12)))$')
}

function Copy-SkillTree([string]$From, [string]$To) {
    if (Test-Path -LiteralPath $To) { throw "Đích đã tồn tại: $To" }
    New-Item -ItemType Directory -Path $To | Out-Null
    foreach ($item in (Get-ChildItem -LiteralPath $From -Force)) {
        if ($item.Name -eq '.git') { continue }
        if (Test-ForbiddenName $item.Name) { throw "Nguồn chứa file có thể là secret: $($item.FullName)" }
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Nguồn chứa link; không tự theo link: $($item.FullName)"
        }
        $target = Join-Path $To $item.Name
        if ($item.PSIsContainer) { Copy-SkillTree $item.FullName $target }
        else { Copy-Item -LiteralPath $item.FullName -Destination $target }
    }
}

function Add-RegistryEntry([string]$Name, [string]$Type, [string]$Version, [string]$Status, [string[]]$Tags = @()) {
    $entry = [pscustomobject]@{
        path = "skills/$Type/$Name"
        version = $Version
        type = $Type
        status = $Status
        tags = @($Tags)
    }
    Add-Member -InputObject $Registry.skills -MemberType NoteProperty -Name $Name -Value $entry
    Write-Json $RegistryFile $Registry
}

function Get-Agent([string]$Name) {
    Assert-Name $Name
    $agent = Read-Json (Join-Path $Vault "agents/$Name.json")
    if ([string]::IsNullOrWhiteSpace([string]$agent.skill_path)) { throw "Agent '$Name' chưa có skill_path." }
    if (-not [IO.Path]::IsPathRooted([string]$agent.skill_path)) { throw "skill_path phải là đường dẫn tuyệt đối." }
    return $agent
}

function Get-AgentOption([string[]]$Arguments) {
    $index = [array]::IndexOf($Arguments, '--agent')
    if ($index -lt 0 -or $index + 1 -ge $Arguments.Count) { throw 'Cần --agent <tên-agent>.' }
    return $Arguments[$index + 1]
}

function Get-Deployment([string]$Name, [string]$AgentName) {
    $agent = Get-Agent $AgentName
    return (Join-Path ([IO.Path]::GetFullPath([string]$agent.skill_path)) $Name)
}

function Get-FileInventory([string]$Root) {
    foreach ($file in (Get-ChildItem -LiteralPath $Root -Recurse -File -Force | Sort-Object FullName)) {
        $relative = $file.FullName.Substring($Root.Length).TrimStart('\','/').Replace('\','/')
        if ($relative -eq '.skill-vault-deployment.json') { continue }
        [pscustomobject]@{ path=$relative; sha256=(Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash }
    }
}

function Test-FileInventory([string]$Root, $Expected) {
    $actual = @(Get-FileInventory $Root)
    $saved = @($Expected)
    if ($actual.Count -ne $saved.Count) { return $false }
    for ($i = 0; $i -lt $actual.Count; $i++) {
        if ($actual[$i].path -cne $saved[$i].path -or $actual[$i].sha256 -ne $saved[$i].sha256) { return $false }
    }
    return $true
}

function Show-List([string]$Filter) {
    if ($Filter -and $Filter -notin @('custom','vendor','incubator')) { throw 'Filter phải là custom, vendor hoặc incubator.' }
    $rows = @($Registry.skills.PSObject.Properties | Sort-Object Name | ForEach-Object {
        $e = $_.Value
        if (-not $Filter -or $e.type -eq $Filter) {
            [pscustomobject]@{ NAME=$_.Name; VERSION=$e.version; TYPE=$e.type; STATUS=$e.status; PATH=$e.path }
        }
    })
    if ($rows.Count -eq 0) { Write-Output '(không có skill)'; return }
    $rows | Format-Table -AutoSize | Out-String -Width 240 | Write-Output
}

function Show-Info([string]$Name) {
    $entry = Get-Entry $Name
    $path = Get-SkillPath $entry
    $front = Get-Frontmatter (Join-Path $path 'SKILL.md')
    $source = Read-Source (Join-Path $path 'SOURCE.yaml')
    Write-Output "Name: $Name"
    Write-Output "Description: $($front.description)"
    Write-Output "Version: $($entry.version)"
    Write-Output "Type: $($entry.type)"
    Write-Output "Status: $($entry.status)"
    Write-Output "Path: $path"
    Write-Output "Source: $($source.source)"
    Write-Output "Upstream commit: $($source.upstream_commit)"
    foreach ($config in (Get-ChildItem -LiteralPath (Join-Path $Vault 'agents') -Filter '*.json' -File)) {
        try {
            $agent = Read-Json $config.FullName
            if (-not $agent.skill_path) { continue }
            $deployment = Join-Path ([string]$agent.skill_path) $Name
            if (Test-Path -LiteralPath $deployment) {
                $mode = if ((Get-Item -LiteralPath $deployment -Force).Attributes -band [IO.FileAttributes]::ReparsePoint) {
                    'link'
                } elseif (Test-Path -LiteralPath (Join-Path $deployment '.skill-vault-deployment.json')) {
                    'copy managed by Vault'
                } else {
                    'copy chưa được Vault quản lý'
                }
                Write-Output "Agent: $($agent.name) ($mode, $deployment)"
            }
        } catch { Write-Warning "Không đọc được agent config $($config.Name): $_" }
    }
}

function New-Skill([string]$Name) {
    Assert-Name $Name
    if (Test-Registered $Name) { throw "Skill '$Name' đã tồn tại trong registry." }
    $dest = Join-Path $Vault "skills/custom/$Name"
    if (Test-Path -LiteralPath $dest) { throw "Đích đã tồn tại: $dest" }
    $template = Join-Path $Vault 'templates/skill'
    New-Item -ItemType Directory -Path $dest | Out-Null
    foreach ($file in @('SKILL.md','README.md','CHANGELOG.md')) {
        $raw = [IO.File]::ReadAllText((Join-Path $template $file), [Text.Encoding]::UTF8)
        $raw = $raw.Replace('example-skill', $Name).Replace('Example skill', $Name)
        [IO.File]::WriteAllText((Join-Path $dest $file), $raw, $Utf8)
    }
    foreach ($dir in @('assets','examples','tests')) {
        $folder = New-Item -ItemType Directory -Path (Join-Path $dest $dir)
        [IO.File]::WriteAllText((Join-Path $folder.FullName '.gitkeep'), '', $Utf8)
    }
    Add-RegistryEntry $Name 'custom' '0.1.0' 'draft'
    Write-Output "Đã tạo: $dest"
}

function Import-Skill([string]$InputPath) {
    if (-not (Test-Path -LiteralPath $InputPath -PathType Container)) { throw "Chỉ nhận thư mục skill cục bộ có SKILL.md: $InputPath" }
    $sourcePath = (Resolve-Path -LiteralPath $InputPath).Path
    $front = Get-Frontmatter (Join-Path $sourcePath 'SKILL.md')
    $name = if ($front.name) { [string]$front.name } else { Split-Path $sourcePath -Leaf }
    Assert-Name $name
    if (Test-Registered $name) { throw "Skill '$name' đã tồn tại trong registry." }
    $dest = Join-Path $Vault "skills/incubator/$name"
    if (Test-Path -LiteralPath $dest) { throw "Đích đã tồn tại: $dest" }
    $version = if ($front.version -match '^\d+\.\d+\.\d+$') { $front.version } else { '0.1.0' }
    $upstream = ''
    $commit = ''
    $repoRoot = ''
    try { $repoRoot = [string](& git -C $sourcePath rev-parse --show-toplevel 2>$null) } catch { }
    if ($repoRoot -and [IO.Path]::GetFullPath($repoRoot) -ne $Vault) {
        try { $commit = [string](& git -C $sourcePath rev-parse HEAD 2>$null) } catch { }
        try { $upstream = [string](& git -C $sourcePath remote get-url origin 2>$null) } catch { }
    }
    try {
        Copy-SkillTree $sourcePath $dest
        $oldSource = Join-Path $dest 'SOURCE.yaml'
        if (Test-Path -LiteralPath $oldSource) { Move-Item -LiteralPath $oldSource -Destination (Join-Path $dest 'SOURCE.upstream.yaml') }
        $fields = @{
            name=$name; source=$upstream; upstream_version=''; upstream_commit=$commit
            downloaded=(Get-Date -Format 'yyyy-MM-dd'); license=''; modified=$false
            local_version=$version; review_status='unreviewed'
        }
        Write-Source $oldSource $fields
        Add-RegistryEntry $name 'incubator' $version 'unreviewed'
    } catch {
        if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
        throw
    }
    Write-Output "Đã import vào incubator: $dest"
}

function Promote-Skill([string]$Name, [string]$TargetType) {
    if ($TargetType -notin @('vendor','custom')) { throw 'Đích phải là vendor hoặc custom.' }
    $entry = Get-Entry $Name
    if ($entry.type -ne 'incubator') { throw 'Chỉ promote skill từ incubator.' }
    $from = Get-SkillPath $entry
    $to = Join-Path $Vault "skills/$TargetType/$Name"
    if (Test-Path -LiteralPath $to) { throw "Đích đã tồn tại: $to" }
    Move-Item -LiteralPath $from -Destination $to
    $sourceFile = Join-Path $to 'SOURCE.yaml'
    $source = Read-Source $sourceFile
    $source['review_status'] = 'reviewed'
    $source['modified'] = ($TargetType -eq 'custom')
    Write-Source $sourceFile $source
    $entry.path = "skills/$TargetType/$Name"
    $entry.type = $TargetType
    $entry.status = 'stable'
    Write-Json $RegistryFile $Registry
    Write-Output "Đã promote: $Name -> $TargetType"
}

function Fork-Skill([string]$Name, [string]$NewName) {
    $entry = Get-Entry $Name
    if ($entry.type -ne 'vendor') { throw 'Chỉ fork từ vendor.' }
    Assert-Name $NewName
    if (Test-Registered $NewName) { throw "Skill '$NewName' đã tồn tại." }
    $dest = Join-Path $Vault "skills/custom/$NewName"
    Copy-SkillTree (Get-SkillPath $entry) $dest
    Set-FrontmatterValue (Join-Path $dest 'SKILL.md') 'name' $NewName
    $source = Read-Source (Join-Path $dest 'SOURCE.yaml')
    $source['name'] = $NewName
    $source['based_on'] = $Name
    $source['modified'] = $true
    $source['review_status'] = 'reviewed'
    Write-Source (Join-Path $dest 'SOURCE.yaml') $source
    Add-RegistryEntry $NewName 'custom' ([string]$entry.version) 'draft' @($entry.tags)
    Write-Output "Đã fork: $Name -> $NewName"
}

function Install-Skill([string]$Name, [string]$AgentName, [bool]$AsLink) {
    $entry = Get-Entry $Name
    $source = Get-SkillPath $entry
    if (-not (Test-Path -LiteralPath $source)) { throw "Thiếu source: $source" }
    $agent = Get-Agent $AgentName
    $agentRoot = [IO.Path]::GetFullPath([string]$agent.skill_path)
    if (-not (Test-Path -LiteralPath $agentRoot -PathType Container)) { throw "Agent skill_path chưa tồn tại: $agentRoot" }
    $dest = Join-Path $agentRoot $Name
    if (Test-Path -LiteralPath $dest) { throw "Deployment đã tồn tại, không ghi đè: $dest" }
    if ($AsLink) {
        try { New-Item -ItemType SymbolicLink -Path $dest -Target $source -ErrorAction Stop | Out-Null }
        catch { throw "Không tạo được symlink ($($_.Exception.Message)). Dùng 'install $Name --agent $AgentName' để copy." }
        Write-Output "Đã link: $dest -> $source"
    } else {
        try {
            Copy-SkillTree $source $dest
            $manifest = [pscustomobject]@{
                vault_root=$Vault; skill=$Name; source_path=$source; version=$entry.version
                files=@(Get-FileInventory $dest)
            }
            Write-Json (Join-Path $dest '.skill-vault-deployment.json') $manifest
        } catch {
            if (Test-Path -LiteralPath $dest) { Remove-Item -LiteralPath $dest -Recurse -Force }
            throw
        }
        Write-Output "Đã copy: $dest"
    }
}

function Uninstall-Skill([string]$Name, [string]$AgentName) {
    $entry = Get-Entry $Name
    $source = Get-SkillPath $entry
    $dest = Get-Deployment $Name $AgentName
    if (-not (Test-Path -LiteralPath $dest)) { throw "Chưa có deployment: $dest" }
    $item = Get-Item -LiteralPath $dest -Force
    if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
        $target = [string]$item.Target
        if ([IO.Path]::GetFullPath($target) -ne [IO.Path]::GetFullPath($source)) {
            throw 'Link này không trỏ tới source đã đăng ký; từ chối xóa.'
        }
        Remove-Item -LiteralPath $dest -Force
    } else {
        $manifestFile = Join-Path $dest '.skill-vault-deployment.json'
        if (-not (Test-Path -LiteralPath $manifestFile)) { throw 'Deployment không có manifest của Vault; từ chối xóa.' }
        $manifest = Read-Json $manifestFile
        if ($manifest.vault_root -ne $Vault -or $manifest.skill -ne $Name -or $manifest.source_path -ne $source) {
            throw 'Manifest không khớp; từ chối xóa.'
        }
        if (-not $manifest.files -or -not (Test-FileInventory $dest $manifest.files)) {
            throw 'Deployment có file thêm, thiếu hoặc đã sửa; từ chối xóa.'
        }
        [IO.Directory]::Delete($dest, $true)
    }
    Write-Output "Đã gỡ deployment: $dest"
}

function Install-Pack([string]$PackName, [string]$AgentName) {
    Assert-Name $PackName
    $pack = Read-Json (Join-Path $Vault "packs/$PackName.json")
    $missing = @($pack.skills | Where-Object { -not (Test-Registered $_) })
    if ($missing.Count) { throw "Pack '$PackName' tham chiếu skill chưa tồn tại: $($missing -join ', ')" }
    $agent = Get-Agent $AgentName
    if ($agent.install_mode -notin @('copy','link')) { throw "install_mode của agent '$AgentName' phải là copy hoặc link." }
    foreach ($name in $pack.skills) {
        if (Test-Path -LiteralPath (Get-Deployment $name $AgentName)) { throw "Deployment đã tồn tại: $name; pack chưa được cài." }
    }
    foreach ($name in $pack.skills) { Install-Skill $name $AgentName ($agent.install_mode -eq 'link') }
}

function Export-Skill([string]$Name) {
    $entry = Get-Entry $Name
    $source = Get-SkillPath $entry
    $output = Join-Path $Vault "exports/$Name-v$($entry.version).zip"
    if (Test-Path -LiteralPath $output) { throw "Package đã tồn tại: $output" }
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::Open($output, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in (Get-ChildItem -LiteralPath $source -Recurse -File -Force)) {
            $relative = $file.FullName.Substring($source.Length).TrimStart('\','/')
            $parts = $relative -split '[\\/]'
            if ($parts | Where-Object { $_ -eq '.git' -or $_ -match '^(?i:(tmp|temp|__pycache__|node_modules))$' -or (Test-ForbiddenName $_) -or $_ -match '\.(?i:tmp|bak|log)$' }) { continue }
            if ($relative -eq '.skill-vault-deployment.json') { continue }
            if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Package chứa link: $relative" }
            if ($file.Extension -match '^(?i:\.(md|txt|yaml|yml|json|ps1|psm1|sh|bat|cmd|py|js))$') {
                $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
                if ($content -match '(?i)-----BEGIN [A-Z ]*PRIVATE KEY-----|(?:sk-|ghp_|github_pat_|AKIA)[A-Za-z0-9_-]{16,}|(?:api[_-]?key|token|password|secret)\s*[:=]\s*["''][A-Za-z0-9+/=_-]{16,}') {
                    throw "Package có dấu hiệu secret trong $relative; từ chối export."
                }
            }
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $file.FullName, ($relative.Replace('\','/'))) | Out-Null
        }
    } catch {
        $zip.Dispose()
        Remove-Item -LiteralPath $output -Force
        throw
    }
    $zip.Dispose()
    Write-Output "Đã export: $output"
}

function Audit-Skill([string]$Name) {
    $entry = Get-Entry $Name
    $path = Get-SkillPath $entry
    $findings = New-Object System.Collections.Generic.List[string]
    $skillFile = Join-Path $path 'SKILL.md'
    if (-not (Test-Path -LiteralPath $skillFile)) { $findings.Add('ERROR: thiếu SKILL.md') }
    else {
        try {
            $front = Get-Frontmatter $skillFile
            foreach ($key in @('name','description','version')) {
                if (-not $front[$key]) { $findings.Add("ERROR: thiếu metadata $key") }
            }
            if ($front.name -ne $Name) { $findings.Add('WARN: name trong SKILL.md khác registry') }
            if ($front.version -notmatch '^\d+\.\d+\.\d+$') { $findings.Add('ERROR: version không đúng semantic version') }
            if ($front.version -ne $entry.version) { $findings.Add('WARN: version khác registry') }
        } catch { $findings.Add("ERROR: $($_.Exception.Message)") }
    }
    if ($entry.type -in @('vendor','incubator') -and -not (Test-Path -LiteralPath (Join-Path $path 'SOURCE.yaml'))) {
        $findings.Add('ERROR: thiếu SOURCE.yaml')
    }
    foreach ($file in (Get-ChildItem -LiteralPath $path -Recurse -File -Force)) {
        $relative = $file.FullName.Substring($path.Length).TrimStart('\','/')
        if (Test-ForbiddenName $file.Name) { $findings.Add("WARN: file có thể là secret: $relative") }
        if ($file.Extension -match '^(?i:\.(ps1|psm1|sh|bat|cmd|py|js|exe|dll))$') { $findings.Add("REVIEW: script/binary: $relative") }
        if (($file.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { $findings.Add("REVIEW: link: $relative") }
        if ($file.Extension -notmatch '^(?i:\.(md|txt|yaml|yml|json|ps1|psm1|sh|bat|cmd|py|js))$') { continue }
        $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
        if ($content -match 'https?://') { $findings.Add("REVIEW: URL bên ngoài: $relative") }
        if ($content -match '(?i)(api[_ -]?key|access[_ -]?token|password|credential|cookie|private key)') { $findings.Add("REVIEW: nhắc tới credentials: $relative") }
        if ($content -match '(?i)(upload|send|post|exfiltrat|Invoke-WebRequest|curl).{0,100}(https?://|internet|server|endpoint)') { $findings.Add("REVIEW: có thể gửi dữ liệu ra Internet: $relative") }
        if ($content -match '(?i)(Remove-Item\s+.*-Recurse|rm\s+-rf|format\s+[A-Z]:|git\s+reset\s+--hard|Invoke-Expression|iex\s*\(|eval\s*\()') { $findings.Add("REVIEW: command nguy hiểm: $relative") }
    }
    Write-Output "Audit: $Name ($($entry.type), $($entry.version))"
    if ($findings.Count -eq 0) { Write-Output 'PASS: không phát hiện vấn đề cơ bản.' }
    else { $findings | Sort-Object -Unique | ForEach-Object { Write-Output $_ } }
    Write-Output 'Audit chỉ báo cáo; hãy review thủ công trước khi promote hoặc chạy skill bên ngoài.'
}

function Show-Status {
    $branch = & git -c "safe.directory=$Vault" -C $Vault branch --show-current 2>$null
    Write-Output "Git branch: $branch"
    $changes = @(& git -c "safe.directory=$Vault" -C $Vault status --short 2>$null)
    if ($changes.Count) { Write-Output 'Git changes:'; $changes | ForEach-Object { Write-Output "  $_" } }
    else { Write-Output 'Git changes: clean' }
    foreach ($property in $Registry.skills.PSObject.Properties) {
        if (-not (Test-Path -LiteralPath (Get-SkillPath $property.Value))) { Write-Output "MISMATCH: registry thiếu thư mục $($property.Name)" }
    }
    foreach ($kind in @('custom','vendor','incubator')) {
        foreach ($dir in (Get-ChildItem -LiteralPath (Join-Path $Vault "skills/$kind") -Directory)) {
            if (-not (Test-Registered $dir.Name)) { Write-Output "MISMATCH: skill chưa đăng ký $kind/$($dir.Name)" }
        }
    }
    foreach ($packFile in (Get-ChildItem -LiteralPath (Join-Path $Vault 'packs') -Filter '*.json' -File)) {
        $pack = Read-Json $packFile.FullName
        foreach ($name in $pack.skills) {
            if (-not (Test-Registered $name)) { Write-Output "WARN: pack $($pack.name) thiếu skill $name" }
        }
    }
    foreach ($agentFile in (Get-ChildItem -LiteralPath (Join-Path $Vault 'agents') -Filter '*.json' -File)) {
        $agent = Read-Json $agentFile.FullName
        if (-not (Test-Path -LiteralPath ([string]$agent.skill_path) -PathType Container)) { Write-Output "WARN: agent $($agent.name) skill_path không tồn tại"; continue }
        foreach ($property in $Registry.skills.PSObject.Properties) {
            $deployment = Join-Path ([string]$agent.skill_path) $property.Name
            if (-not (Test-Path -LiteralPath $deployment)) { continue }
            $item = Get-Item -LiteralPath $deployment -Force
            if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
                if ([IO.Path]::GetFullPath([string]$item.Target) -ne [IO.Path]::GetFullPath((Get-SkillPath $property.Value))) {
                    Write-Output "MISMATCH: agent $($agent.name) link $($property.Name) trỏ sai"
                }
            } elseif (-not (Test-Path -LiteralPath (Join-Path $deployment '.skill-vault-deployment.json'))) {
                Write-Output "WARN: agent $($agent.name) có bản chưa quản lý: $($property.Name)"
            } else {
                $manifest = Read-Json (Join-Path $deployment '.skill-vault-deployment.json')
                if (-not $manifest.files -or -not (Test-FileInventory $deployment $manifest.files)) {
                    Write-Output "MISMATCH: agent $($agent.name) deployment $($property.Name) đã đổi"
                }
            }
        }
    }
}

function Usage {
    Write-Output 'skillctl list [custom|vendor|incubator]'
    Write-Output 'skillctl info <skill> | new <name> | import <folder> | audit <skill>'
    Write-Output 'skillctl promote <skill> vendor|custom | fork <vendor-skill> <new-name>'
    Write-Output 'skillctl install|link|uninstall <skill> --agent <agent>'
    Write-Output 'skillctl install-pack <pack> --agent <agent> | export <skill> | status'
}

try {
    $Registry = Read-Json $RegistryFile
    if (-not $CliArgs -or $CliArgs.Count -eq 0) { Usage; exit 0 }
    $command = $CliArgs[0]
    $arguments = @($CliArgs | Select-Object -Skip 1)
    switch ($command) {
        'list' { Show-List ([string]$arguments[0]) }
        'info' { Show-Info ([string]$arguments[0]) }
        'new' { New-Skill ([string]$arguments[0]) }
        'import' { Import-Skill ([string]$arguments[0]) }
        'promote' { Promote-Skill ([string]$arguments[0]) ([string]$arguments[1]) }
        'fork' { Fork-Skill ([string]$arguments[0]) ([string]$arguments[1]) }
        'install' { Install-Skill ([string]$arguments[0]) (Get-AgentOption $arguments) $false }
        'link' { Install-Skill ([string]$arguments[0]) (Get-AgentOption $arguments) $true }
        'uninstall' { Uninstall-Skill ([string]$arguments[0]) (Get-AgentOption $arguments) }
        'install-pack' { Install-Pack ([string]$arguments[0]) (Get-AgentOption $arguments) }
        'export' { Export-Skill ([string]$arguments[0]) }
        'audit' { Audit-Skill ([string]$arguments[0]) }
        'status' { Show-Status }
        default { Usage; throw "Command không hỗ trợ: $command" }
    }
    exit 0
} catch {
    [Console]::Error.WriteLine("ERROR: $($_.Exception.Message)")
    exit 1
}
