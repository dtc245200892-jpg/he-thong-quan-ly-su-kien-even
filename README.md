# Hệ thống quản lý sự kiện/Even

Dự án thực hành môn **Triển khai và Quản trị Hệ thống Phần mềm**, theo định hướng Đề 26 trong tài liệu hướng dẫn. Ứng dụng mẫu quản lý sự kiện, đăng ký tham dự và mã vé; PostgreSQL + pgAdmin; Docker Compose; Nginx reverse proxy; Prometheus + Grafana; Loki + Promtail; các cấu hình hardening cơ bản.

> Sinh viên: Diệp Chí Vỹ
> Mã số sinh viên: [điền mã số sinh viên thực tế]
> GitHub repository: [điền URL GitHub repository thực tế]

> Lưu ý trung thực khi nộp: đây là bộ khung triển khai. Hãy tự chạy, kiểm tra trên máy, chụp ảnh minh chứng và thay thông tin sinh viên/GitHub. Không ghi rằng HTTPS đã cấu hình: mẫu này dùng HTTP cục bộ và security headers. HTTPS tự ký có thể bổ sung nếu giảng viên yêu cầu.

## 1. Yêu cầu
- Docker Desktop có Docker Compose v2
- Git
- Trình duyệt web

## 2. Chạy dự án
PowerShell tại thư mục gốc dự án:

```powershell
Copy-Item .env.example .env
notepad .env
# Sửa các mật khẩu mẫu thành mật khẩu mạnh, riêng biệt

docker compose config
docker compose up -d --build
docker compose ps
```

Mở các địa chỉ:
- Website qua Nginx: http://localhost:8080
- pgAdmin: http://localhost:5050 (email/password trong `.env`; thêm server host `db`, port `5432`, database `even_db`, user `even_app`, password `DB_PASSWORD`)
- Prometheus: http://localhost:9090
- Grafana: http://localhost:3001 (đăng nhập theo `.env`)
- Loki API: http://localhost:3100/ready (có thể chỉ truy cập trên máy cục bộ)

## 3. Chức năng
- Xem danh sách sự kiện và số lượt đăng ký
- Thêm sự kiện
- Đăng ký tham dự, sinh mã vé
- Xóa sự kiện
- API: `GET /health`, `GET /api/events`, `POST /api/events`, `GET /api/registrations`, `GET /metrics`

Đây là bản thực hành tối thiểu, chưa có xác thực/ phân quyền tài khoản quản trị. Không triển khai công khai trên Internet trước khi bổ sung xác thực, HTTPS, giới hạn truy cập và rà soát bảo mật.

## 4. GitHub và 3 commit theo tiêu chí
Tạo repository GitHub với tên theo mã số sinh viên theo yêu cầu giảng viên. Không commit file `.env`.

```bash
git init
git add .
git commit -m "commit 1: deploy app database and nginx reverse proxy"
# Kiểm tra website, PostgreSQL, pgAdmin, headers rồi ghi lại minh chứng

git add .
git commit -m "commit 2: add prometheus grafana monitoring"
# Kiểm tra targets trong Prometheus và datasource Grafana

git add .
git commit -m "commit 3: add loki promtail logging and hardening"
```

Ba commit phải phản ánh công việc thực tế; nếu làm theo từng giai đoạn, chỉ commit phần đã hoàn thành và chụp ảnh màn hình minh chứng.

## 5. Kiểm thử
```powershell
curl.exe http://localhost:8080/health
curl.exe http://localhost:8080/api/events
curl.exe -I http://localhost:8080/
curl.exe http://localhost:8080/metrics
```

## 6. Prometheus
Vào http://localhost:9090/targets. Kiểm tra `even_app`, `postgres`, `containers` và `prometheus`. Một số exporter có thể cần điều chỉnh theo hệ điều hành/phiên bản Docker. Chỉ ghi nhận `UP` khi đã xác minh thực tế.

Các metric ứng dụng: `even_events_total`, `even_registrations_total`. Trong Grafana, tạo dashboard và panel với các query PromQL:
- `even_events_total`
- `even_registrations_total`
- `up`
- `container_memory_usage_bytes`

## 7. Loki / LogQL
Trong Grafana Explore chọn datasource Loki. Thử các truy vấn sau sau khi đã xác minh Promtail thu thập được log:
- `{job="docker"}`
- `{job="docker"} |= "event_created"`
- `{job="docker"} |= "registration_created"`

Trên Docker Desktop/Windows, đường dẫn log container và quyền đọc có thể khác Linux; nếu không thấy log, xem phần Troubleshooting và ghi rõ cấu hình đã kiểm chứng trên máy.

## 8. Hardening được cấu hình
- Ứng dụng Node chạy bằng user không phải root.
- App dùng filesystem read-only và tmpfs cho `/tmp`.
- `no-new-privileges` và drop capabilities cho app/Nginx.
- PostgreSQL nằm trong network backend nội bộ, không publish cổng ra host.
- pgAdmin, Prometheus, Grafana và Loki chỉ bind vào `127.0.0.1`.
- Mật khẩu đưa qua `.env`, file `.env` nằm trong `.gitignore`.
- Nginx có security headers và giới hạn kích thước request.

Lưu ý: cAdvisor cần quyền cao để đọc số liệu container, và Promtail đọc log Docker; đây là ngoại lệ cần nêu trong báo cáo. Mẫu Nginx dùng security headers nhưng chưa bật HTTPS.

## 9. Troubleshooting
- `DB_PASSWORD is required`: sao chép `.env.example` thành `.env` và chỉnh biến.
- Không mở được website: chạy `docker compose ps` và `docker compose logs app db nginx`.
- App chưa kết nối DB: đợi healthcheck rồi thử lại; kiểm tra `docker compose logs db app`.
- Cổng bị chiếm: đổi cổng host ở vế trái trong `ports`.
- Không có log Loki: kiểm tra `docker compose logs promtail loki`; đường dẫn log bind mount có thể khác trên Windows.
- Exporter không `UP`: kiểm tra log exporter, quyền Docker và cấu hình exporter trên hệ điều hành.

## 10. Dọn dẹp
`docker compose down` dừng dịch vụ. `docker compose down -v` xóa cả dữ liệu volume PostgreSQL/Prometheus/Grafana/Loki; chỉ dùng khi chấp nhận mất dữ liệu.
