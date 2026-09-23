---
name: social-promo-banner-style
description: Tạo banner, media social post và ảnh quảng bá theo phong cách commercial hiện đại: ít chữ, dễ đọc, màu tiết chế, hierarchy mạnh, có 1 hero hook rõ ràng, dùng logo/model image reference bắt buộc để giữ đúng nhận diện.
version: 1.0.0
language: vi
---

# Social Promo Banner Style

## 1. Mục tiêu
Tạo banner/social media post quảng bá model AI, sản phẩm số, campaign sale, bonus, relaunch hoặc event theo phong cách **commercial design hiện đại, dễ đọc, gọn, có điểm nhấn mạnh nhưng không phô hiệu ứng AI**.

Ưu tiên theo thứ tự:
1. Readability ở kích thước thumbnail.
2. Một thông điệp chính thật rõ.
3. Brand/model recognition chính xác.
4. Màu hài hòa, saturation vừa phải.
5. Bố cục có hệ thống như banner do designer dựng.
6. Visual đủ hấp dẫn nhưng không lấn át thông tin.

## 2. Điều kiện bắt buộc về image reference
Mỗi task tạo banner phải có **ít nhất 1 ảnh tham chiếu logo/wordmark của model hoặc brand**.

Phân loại reference:
- **Identity ref — bắt buộc:** logo/wordmark/model mark. Dùng để giữ đúng hình dáng, tỷ lệ và nhận diện.
- **Product ref — tùy chọn:** UI screenshot, giao diện model, mascot, 3D object, product shot.
- **Output ref — tùy chọn:** ví dụ ảnh/video do model tạo.
- **Style ref — tùy chọn:** banner mẫu để tham chiếu mood, layout, palette, density.

Nếu chưa có identity ref, yêu cầu người dùng cung cấp logo/model image trước khi tạo. Không tự bịa logo hoặc biến tấu logo thành biểu tượng mới.

Khi có nhiều ref:
- Identity ref quyết định nhận diện thương hiệu.
- Style ref chỉ quyết định bố cục/mood/độ đậm nhạt.
- Product/output ref chỉ là content phụ trợ.
- Nếu style ref xung đột màu với brand, giữ nhận diện brand và chỉ mượn cấu trúc/layout từ style ref.

## 3. DNA thẩm mỹ
Phong cách mặc định:
- commercial social design
- clean, modern, readable
- strong typography hierarchy
- restrained color palette
- modular card/panel layout
- soft gradients, soft shadows, controlled glow
- premium tech aesthetic
- social-friendly
- not overly AI-looking

Không cố làm “art”. Đây là **thiết kế quảng cáo**, không phải concept art.

## 4. Luật cứng về nội dung
Mỗi banner chỉ có **1 hero hook**.

Hero hook thường là một trong các dạng:
- `GIẢM 30%`
- `50%`
- `CHỈ 100đ/1s`
- `3 CREDITS`
- `TẶNG 2.000 CREDITS`
- `MỞ LẠI GROK VIDEO`
- `ĐẠI TIỆC KLING`

Không để hai headline có cùng mức độ ưu tiên tranh nhau.

### Text budget mặc định
Ưu tiên tối đa 5 nhóm chữ:
1. Brand/model.
2. Hero hook.
3. Supporting line.
4. Giá/credits/thời gian.
5. CTA.

Mục tiêu tổng text hiển thị: **15–35 từ**, không tính tên brand, số, ngày tháng. Không dùng paragraph dài.

Giữ nguyên tuyệt đối:
- con số
- phần trăm
- credits
- giá tiền
- ngày/tháng
- tên model
- dấu tiếng Việt

Không tự thêm ưu đãi, giá hoặc điều kiện không có trong brief.

## 5. Typography hierarchy
Tối đa 3 tầng hierarchy:

### Tier 1 — Hero
- lớn nhất ảnh
- bold/heavy
- có thể dùng soft 3D, gradient, highlight hoặc glow nhẹ
- chỉ một hero duy nhất

### Tier 2 — Supporting
- tên model, subheadline, giá chính
- rõ nhưng nhỏ hơn hero đáng kể

### Tier 3 — Meta
- thời gian, điều kiện ngắn, tag, label
- nhỏ, tương phản vừa đủ

Ưu tiên sans-serif hiện đại. Tối đa 2 kiểu font/weight system. Không dùng nhiều font trang trí.

Handwritten/script chỉ được dùng cho **một câu cực ngắn mang tính accent** và không được cạnh tranh với hero.

## 6. Màu sắc
Mục tiêu: **màu đẹp nhưng không gắt**.

Tỷ lệ tham khảo:
- 70–85% base/background
- 10–20% accent chính
- <=10% highlight

Chỉ dùng 1 accent chính và tối đa 1 accent phụ.

### Palette ưu tiên
**Clean Light**
- white / warm white / light gray
- charcoal / black
- red-orange hoặc brand accent

**Dark Tech**
- black / deep navy
- white
- cyan / aqua / green-blue / lime nhẹ

**Bold Promo**
- black/dark base
- yellow/gold/orange hoặc brand color
- white

**Festive/Event**
- seasonal palette như red + gold + white
- vẫn phải giữ text clean và hạn chế chi tiết nền

Tránh:
- rainbow
- nhiều neon cạnh tranh nhau
- full-canvas saturation cao
- background quá sáng làm mất text

## 7. Hiệu ứng
Cho phép:
- soft shadow
- subtle outer glow
- gradient dịu
- thin illuminated stroke
- soft 3D/extrusion cho hero number hoặc badge
- low-opacity light streak

Mỗi banner chỉ nên có **1–2 hiệu ứng chính**.

Không dùng quá mức:
- lens flare
- sparkle/particle
- chrome effect
- glow dày
- texture phức tạp
- cinematic fog

Nguyên tắc: **effect chỉ được dùng để tăng hierarchy, không dùng để khoe hiệu ứng**.

## 8. Shape language
Ưu tiên một hệ hình khối thống nhất:
- rounded cards
- pills
- badges
- compact info panels
- CTA button
- thin outline cards

Giữ corner radius và stroke nhất quán giữa các block.

Không thả từng dòng chữ tự do khắp canvas nếu có thể nhóm vào một block hợp lý.

## 9. Layout library
Chọn layout phù hợp với brief. Không cố nhồi tất cả vào một template.

### L1 — Split Hero
- Trái: brand + headline + offer.
- Phải: logo/object/UI/product visual.
- Hợp: Grok/Kling/model promo, banner 16:9.

### L2 — Center Hero Number
- Brand ở trên.
- %/giá/credits cực lớn giữa ảnh.
- Info + CTA ở dưới.
- Hợp: flash sale, discount, pricing.

### L3 — Hero + Modular Cards
- Headline ở trên.
- 2–3 card model/plan/price ở giữa.
- CTA/time ở dưới.
- Hợp: nhiều phiên bản model hoặc pricing tiers.

### L4 — Product/Logo Object + Offer Panel
- Object/logo lớn một phía.
- Offer panel rõ ràng phía còn lại.
- Hợp: model launch/relaunch, motion-control, feature promo.

### L5 — Clean Light Promo
- Nền sáng nhiều whitespace.
- Logo/model name rõ.
- 1 badge 3D mềm cho % giảm.
- 1 pill giá + 1 pill thời gian.
- Hợp: premium/minimal.

### L6 — Festive Campaign
- Hero event/date + offer.
- 1 visual event/brand anchor.
- Decorative motif chỉ ở viền/background.
- Hợp: lễ/tết/event.

## 10. Whitespace và density
Ảnh phải có vùng nghỉ mắt.

Mặc định:
- Clean light: 25–40% negative space.
- Dark tech: 15–30% negative space.
- Bold promo: vẫn giữ vùng trống quanh hero; không lấp kín toàn bộ canvas.

Nếu nhìn ảnh ở 25% kích thước mà vẫn đọc được **brand + hero + 1 info quan trọng**, hierarchy đạt yêu cầu.

## 11. CTA
CTA ngắn 2–4 từ:
- Tạo ngay
- Dùng ngay
- Nạp ngay
- Thử ngay
- Nhận ưu đãi

CTA phải rõ nhưng **không lớn hơn hero**.

## 12. Style modes
### A. CLEAN_LIGHT
Dùng khi cần premium/basic/brand-safe.
- nền trắng/xám sáng
- black typography
- 1 accent nóng hoặc brand color
- rất ít glow
- badge 3D mềm

### B. DARK_TECH
Dùng mặc định cho AI video/image models.
- navy/black
- white typography
- cyan/aqua/green accent
- soft neon edge
- panel/card rõ ràng

### C. BOLD_PROMO
Dùng khi sale mạnh, cần CTR cao.
- offer số cực lớn
- dark hoặc high-contrast background
- yellow/gold/orange/brand accent
- visual phụ trợ có kiểm soát

### D. FESTIVE_EVENT
Dùng cho holiday/event.
- lấy màu event làm accent
- không biến toàn ảnh thành ornamental poster
- giữ cấu trúc commercial rõ

### E. MINIMAL_ANNOUNCEMENT
Dùng cho update/reopen/bonus.
- 1 headline rất lớn
- 1 supporting fact
- ít object
- background tech nhẹ

## 13. Aspect ratio mặc định
Nếu người dùng không chỉ định:
- “banner” → 16:9
- “social post/feed” → 4:5
- “post vuông” → 1:1
- “story/reel” → 9:16

## 14. Workflow cho agent
### Bước 1 — Parse brief
Lấy ra:
- brand/model
- identity logo ref
- campaign type
- hero hook
- support info
- time
- CTA
- aspect ratio
- optional refs

### Bước 2 — Kiểm tra ref bắt buộc
Nếu không có logo/model identity ref → yêu cầu cung cấp ref.

### Bước 3 — Chọn mode
Tự chọn mode phù hợp nếu người dùng không chỉ định. Không hỏi thêm nếu có thể suy ra hợp lý.

### Bước 4 — Compress copy
Rút text xuống phần cần thiết. Không thay đổi ý nghĩa hoặc con số.

### Bước 5 — Chọn layout
Chọn 1 layout từ L1–L6 dựa trên số lượng thông tin và asset.

### Bước 6 — Xây hierarchy
Chốt:
- Hero
- Supporting
- Meta
- CTA

### Bước 7 — Generate/design
Dùng công cụ image/design hiện có. Logo ref là identity anchor. Không biến logo thành vật thể khác nếu user không yêu cầu.

### Bước 8 — Quality check
Kiểm tra:
- logo có đúng không?
- text có sai chính tả/diacritics không?
- số/giá/ngày có đúng không?
- có nhiều hơn 1 hero không?
- background có tranh spotlight không?
- màu có quá saturation không?
- CTA có rõ nhưng không quá lớn không?
- ảnh có nhìn như banner commercial thật không?

Nếu tool hỗ trợ refinement, tự sửa lỗi rõ ràng trước khi đưa kết quả cuối.

## 15. Negative rules
Không tạo:
- nhiều paragraph
- quá nhiều icon
- quá nhiều màu accent
- background rối hơn nội dung
- 3D quá nặng cho tất cả text
- nhiều font style không liên quan
- hàng loạt flare/sparkle
- fantasy/cinematic poster khi brief là promo banner
- logo giả hoặc logo bị biến dạng
- text placeholder vô nghĩa
- CTA cạnh tranh với hero

## 16. Prompt core dùng cho image model
Dùng ý sau làm lõi prompt, sau đó chèn nội dung task:

> Create a modern commercial social-media promotional banner with strong readability and disciplined visual hierarchy. Use the provided brand/model logo image as the primary identity reference and preserve its recognizable geometry and wordmark. Keep the copy concise. Use one dominant hero hook, a limited color palette, controlled saturation, clean modular cards/pills, generous spacing, and restrained gradients, soft shadows or subtle glow. The result should look like professional campaign design, not AI concept art. Make the offer instantly readable at thumbnail size. Do not invent extra pricing, dates, logos or claims. Avoid visual clutter, excessive neon, excessive particles, heavy lens flares, and competing focal points.

## 17. User-facing behavior
Khi brief đã đủ:
- không giảng giải dài dòng trước khi làm
- thực hiện trực tiếp
- chỉ hỏi khi thiếu identity logo ref hoặc thiếu thông tin làm thay đổi nội dung chính

Khi người dùng yêu cầu chỉnh sửa:
- giữ nguyên những phần họ đã duyệt
- chỉ thay đúng phần được yêu cầu
- không tự đổi palette/layout nếu không cần thiết

## 18. Tiêu chuẩn đạt
Banner được coi là đúng skill khi:
- nhìn 1 giây hiểu được offer chính
- brand/model rõ
- ít chữ
- palette gọn
- hierarchy rõ
- có vùng thở
- effect có kiểm soát
- text và số chính xác
- có cảm giác designer-made, không “AI quá”
