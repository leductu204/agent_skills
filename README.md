# Skill Vault

Đây là kho Git chung cho skill cá nhân, skill lấy từ bên ngoài, knowledge base và các pack dùng cho nhiều agent. Đường dẫn hiện tại là `E:\agent-skills`. Thư mục agent chỉ chứa bản được copy hoặc link từ Vault.

## Kiến trúc

Internet/GitHub → `skills/incubator` → review bằng `audit` và đọc thủ công → `skills/vendor` hoặc `skills/custom` → `packs` → deploy sang agent.

- `skills/custom`: skill tự viết hoặc đã fork và chỉnh nhiều.
- `skills/vendor`: skill bên ngoài được giữ gần upstream.
- `skills/incubator`: skill bên ngoài chưa review. Import chỉ copy file, không chạy script, hook hay cài dependency.
- `knowledge`: context và tài liệu tham khảo dùng chung; knowledge base không phải skill.
- `packs`: nhóm tên skill theo workflow. Pack có thể tham chiếu skill chưa tồn tại; `status` sẽ cảnh báo.
- `agents`: mỗi file JSON xác định `skill_path`, `install_mode` và `default_packs` của một agent. Thêm agent bằng file mới, không sửa logic core.
- `templates/skill`: bộ khung cho skill mới. `exports` chứa zip và được Git bỏ qua.

Registry dùng `registry.json` vì Windows PowerShell 5.1 mặc định có JSON parser nhưng không có YAML parser. `SOURCE.yaml` vẫn lưu provenance theo mẫu đơn giản. Mỗi skill dùng version `MAJOR.MINOR.PATCH`: PATCH cho sửa nhỏ, MINOR cho capability tương thích, MAJOR cho thay đổi behavior đáng kể. Tăng version skill trước thay đổi lớn và commit Git sau khi ổn định.

## Quy tắc

Vault là source of truth. Không sửa skill trực tiếp trong folder agent; hãy sửa tại Vault rồi cài lại bản copy hoặc dùng link. Skill từ Internet phải vào incubator trước. Không commit token, API key, cookie, credentials, `.env` hay private key. `audit` là kiểm tra tĩnh cơ bản và không thay thế review thủ công.

`install` tạo bản copy có manifest và từ chối ghi đè deployment sẵn có. `link` tạo symbolic link nếu Windows cho phép; nếu không, CLI báo lỗi và gợi ý `install`. `uninstall` chỉ xóa deployment do Vault quản lý, không xóa source. `export` từ chối ghi đè zip, bỏ qua `.git`, cache, temp và file giống secret. Lệnh `import` hiện nhận thư mục cục bộ có `SKILL.md`; để lấy từ Internet, tải/clone vào một thư mục tạm trước rồi import. CLI không thực thi code của skill được import.

Hai file Markdown có sẵn ở root được giữ nguyên như bản gốc lịch sử. Bản quản lý nằm trong `skills/` và `knowledge/`.

## Quick start

Chạy từ root Vault bằng Windows PowerShell:

```powershell
.\skillctl.ps1 list
.\skillctl.ps1 new my-skill
.\skillctl.ps1 import C:\Downloads\some-skill
.\skillctl.ps1 audit some-skill
.\skillctl.ps1 promote some-skill vendor
.\skillctl.ps1 install some-skill --agent codex
.\skillctl.ps1 link some-skill --agent codex
.\skillctl.ps1 uninstall some-skill --agent codex
.\skillctl.ps1 install-pack marketing --agent codex
.\skillctl.ps1 export some-skill
.\skillctl.ps1 status
```

`promote` là quyết định review của người dùng; hãy đọc `SOURCE.yaml`, `SKILL.md`, các script và kết quả `audit` trước khi chạy. Nếu muốn tự tùy biến vendor skill, dùng `fork <vendor-skill> <new-name>` rồi sửa bản custom.

Pack `marketing` là ví dụ và hiện cố ý tham chiếu `marketing-research` chưa có. `install-pack marketing` sẽ từ chối cài cho đến khi pack hợp lệ. Cấu hình Codex đã được xác định từ máy hiện tại trong `agents/codex.json`; các agent khác cần file JSON tương ứng.
