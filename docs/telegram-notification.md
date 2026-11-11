# Gửi thông báo cảnh báo qua Telegram (tùy chọn)

Alertmanager v0.27.0 hỗ trợ sẵn `telegram_configs` (các trường: `bot_token` hoặc `bot_token_file` (chỉ chọn một), `chat_id`, `parse_mode`, `send_resolved`, `message`). File mẫu: `config/alertmanager.telegram.example.yml`.

> Chỉ dùng **bot và nhóm Telegram test của nhóm**. Không commit token, không dùng kênh của VNPT.

## 1. Tạo bot và lấy chat_id
1. Trên Telegram nhắn `@BotFather`, gõ `/newbot`, đặt tên, nhận **token**.
2. Tạo nhóm test, thêm bot vào nhóm, gửi một tin bất kỳ trong nhóm.
3. Mở trên trình duyệt `https://api.telegram.org/bot<TOKEN>/getUpdates` và lấy `chat.id` (nhóm thường là số âm).

## 2. Đặt token ngoài Git
```bash
mkdir secrets
echo "<TOKEN>" > secrets/telegram_token   # thư mục secrets/ đã nằm trong .gitignore
```

## 3. Bật cấu hình
1. Sửa `chat_id` trong `config/alertmanager.telegram.example.yml`, rồi copy thành `config/alertmanager.yml` trên **máy của bạn** (đừng commit chat_id thật nếu nhóm không muốn công khai).
2. Trong `docker-compose.yml`, ở service alertmanager thêm volume:
   `- ./secrets:/etc/alertmanager/secrets:ro`
3. Kiểm tra cú pháp rồi nạp lại:
```bash
docker compose exec alertmanager amtool check-config /etc/alertmanager/alertmanager.yml
docker compose up -d alertmanager
```
(Đường dẫn file cấu hình trong container tùy theo docker-compose của nhóm.)

## 4. Thử
Chạy `bash scenarios/03_service_down.sh`: sẽ nhận tin CẢNH BÁO, và tin ĐÃ KHẮC PHỤC khi dịch vụ lên lại (sau `group_interval`). Chụp ảnh tin nhắn bỏ vào `scenarios/results/`.

## Lưu ý
- Mất khoảng `group_wait` (10s) + thời gian `for:` mới có tin đầu tiên.
- Lộ token: vào `@BotFather` chọn `/revoke` để cấp token mới.
