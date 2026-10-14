# Dàn ý báo cáo thực hành — Hệ thống quản lý sự kiện/Even

> Báo cáo cuối cùng cần tối thiểu 10 trang theo hướng dẫn môn học. Thay các trường trong ngoặc vuông bằng thông tin thật và chèn ảnh chụp màn hình thực tế sau khi chạy hệ thống. Không dùng ảnh minh họa giả làm minh chứng.

## Bìa
- Trường/khoa: [điền theo mẫu của trường]
- Môn: Triển khai và Quản trị Hệ thống Phần mềm
- Đề tài: **Hệ thống quản lý sự kiện/Even**
- Sinh viên: Diệp Chí Vỹ
- Mã số sinh viên: [điền]
- Lớp: [điền]
- Giảng viên: [điền]
- Thái Nguyên, 2026

## 1. Tổng quan
Mục tiêu của dự án là triển khai một website quản lý sự kiện có khả năng tạo sự kiện, ghi nhận người đăng ký và tạo mã vé. Ngoài chức năng nghiệp vụ, dự án thực hành quy trình đóng gói và vận hành nhiều dịch vụ bằng Docker Compose, đặt Nginx làm reverse proxy, giám sát metrics với Prometheus/Grafana và tập trung log bằng Loki/Promtail.

Phạm vi bản mẫu: quản lý sự kiện, đăng ký tham dự, mã vé, PostgreSQL, pgAdmin, reverse proxy, metrics, logging và hardening cơ bản. Xác thực người dùng, thanh toán thật và gửi email chưa nằm trong phạm vi.

## 2. Kiến trúc hệ thống
Trình bày các dịch vụ: trình duyệt → Nginx → ứng dụng Node.js/Express → PostgreSQL; pgAdmin quản trị DB; Prometheus thu thập metrics; Grafana hiển thị; Promtail chuyển log sang Loki. Chèn ảnh sơ đồ kiến trúc do sinh viên vẽ và ảnh `docker compose ps` thực tế.

## 3. Triển khai ứng dụng và cơ sở dữ liệu
Mô tả bảng `events` (id, name, location, event_date, capacity, description, created_at) và `registrations` (id, event_id, attendee_name, attendee_email, ticket_code, created_at), khóa chính và khóa ngoại. Chèn ảnh website, pgAdmin và dữ liệu mẫu. Kiểm thử tạo sự kiện và đăng ký.

## 4. Nginx reverse proxy
Mô tả Nginx chuyển tiếp yêu cầu từ cổng 8080 đến app:3000; nêu các header bảo mật đang cấu hình. Mẫu hiện dùng HTTP cục bộ, chưa phải HTTPS. Chèn ảnh truy cập qua Nginx và kết quả `curl -I`.

## 5. Giám sát Prometheus và Grafana
Mô tả scrape interval 15 giây, endpoint `/metrics` và các exporter. Trình bày trạng thái Targets, datasource Grafana, dashboard có `up`, `even_events_total`, `even_registrations_total` và metrics container/DB nếu exporter hoạt động. Chèn ảnh minh chứng thực tế.

## 6. Logging Loki, Promtail và LogQL
Mô tả luồng log container → Promtail → Loki → Grafana Explore. Thử ít nhất 2–3 truy vấn:
- `{job="docker"}`
- `{job="docker"} |= "event_created"`
- `{job="docker"} |= "registration_created"`
Chèn ảnh kết quả thực tế; nếu chưa thu thập được log trên Docker Desktop thì ghi rõ lỗi và cách xử lý, không khẳng định đã thành công.

## 7. Hardening
Nêu non-root app, read-only filesystem, no-new-privileges, drop capabilities, backend network internal, DB không publish port, dashboard bind localhost, mật khẩu trong `.env`, `.env` không commit, Nginx security headers. Nêu ngoại lệ cAdvisor/Promtail cần quyền đọc hệ thống/log. HTTPS chưa bật trong bản mẫu.

## 8. Kiểm thử và kết quả
Tạo bảng test case gồm: mở trang chủ, health check, tạo sự kiện hợp lệ, tạo sự kiện thiếu dữ liệu, đăng ký người tham dự, đăng ký vượt sức chứa, xem API, kiểm tra security headers, Prometheus targets, LogQL query. Điền kết quả thực tế Pass/Fail sau khi chạy.

## 9. Kết luận và hướng phát triển
Tổng kết phần đã kiểm chứng. Hướng phát triển: đăng nhập và phân quyền admin, sửa sự kiện, chống đăng ký trùng email, QR code vé, HTTPS, backup/restore, cảnh báo Grafana và CI/CD.

## 10. Phụ lục
README, cấu trúc thư mục, các lệnh Docker Compose, ảnh ba commit GitHub và đường dẫn repository.
