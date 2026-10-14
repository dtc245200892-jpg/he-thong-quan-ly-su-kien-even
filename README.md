# Hệ thống quản lý sự kiện/Even

Dự án thực hành môn **Triển khai và Quản trị Hệ thống Phần mềm**, theo định hướng Đề 26 trong tài liệu hướng dẫn. Ứng dụng mẫu quản lý sự kiện, đăng ký tham dự và mã vé; PostgreSQL + pgAdmin; Docker Compose; Nginx reverse proxy; Prometheus + Grafana; Loki + Promtail; các cấu hình hardening cơ bản.

> - Sinh viên: Diệp Chí Vỹ
> - Mã số sinh viên: DTC245200892
> - Lớp: CNTT K23N
> - Khoa: Công nghệ thông tin
> - Trường: Trường Đại học Công nghệ Thông tin và Truyền thông
> - Giảng viên hướng dẫn: Vũ Văn Diện
> - GitHub repository: https://github.com/dtc245200892-jpg/he-thong-quan-ly-su-kien-even

> Lưu ý khi nộp: hãy tự chạy, kiểm tra trên máy và chụp ảnh minh chứng thực tế. Không ghi rằng HTTPS đã cấu hình: mẫu này dùng HTTP cục bộ và security headers. HTTPS tự ký có thể bổ sung nếu giảng viên yêu cầu.

## Báo cáo

Bản thảo báo cáo theo yêu cầu môn học nằm trong [REPORT.md](./REPORT.md). Trước khi nộp, cần chèn ảnh chụp minh chứng thực tế vào các vị trí được đánh dấu, xác nhận kết quả truy vấn LogQL sau khi chạy trên máy, rồi dàn trang và kiểm tra báo cáo đạt tối thiểu 10 trang.

## Repository và các giai đoạn commit

Repository đã được khởi tạo trên GitHub. Lịch sử hiện có ba commit theo các giai đoạn được yêu cầu:

1. `commit 1: deploy app database and nginx reverse proxy`
2. `commit 2: add prometheus grafana monitoring`
3. `commit 3: add loki promtail logging and hardening`

Không đưa `.env` lên GitHub; hãy kiểm tra `git status` trước khi push.

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
Repository: https://github.com/dtc245200892-jpg/he-thong-quan-ly-su-kien-even. Không commit file `.env`.

```bash
git --no-pager log --oneline
git status --short
```

Ba commit theo giai đoạn đã có trong lịch sử repository. Nếu có thay đổi tiếp theo, tạo commit mới sau khi kiểm tra nội dung; không đưa `.env` vào Git.

## 5. Kiểm thử
```powershell
curl.exe http://localhost:8080/health
curl.exe http://localhost:8080/api/events
curl.exe -I http://localhost:8080/
curl.exe http://localhost:8080/metrics
```

## 6. Prometheus
Vào http://localhost:9090/targets. Kiểm tra `even_app`, `postgres`, `containers` và `prometheus`. Một số exporter có thể cần điều chỉnh theo hệ điều hành/phiên bản Docker. Dashboard `Even - System Overview` được provision sẵn trong Grafana với panels sự kiện, đăng ký, targets, PostgreSQL và memory container.

Dashboard được provision tự động. Các truy vấn PromQL dùng trong các panels:
- `even_events_total`
- `even_registrations_total`
- `up`
- `pg_up`
- `sum by (id) (container_memory_usage_bytes)`

## 7. Loki / LogQL
Trong Grafana Explore chọn datasource Loki. Thử các truy vấn sau sau khi đã xác minh Promtail thu thập được log:
- `{job="docker"}`
- `{job="docker"} |= "event_created"`
- `{job="docker"} |= "registration_created"`

Promtail đọc file JSON log qua bind mount chỉ đọc tại `/var/lib/docker/containers`. Đường dẫn này đã được xác minh hoạt động trên máy phát triển hiện tại, nhưng có thể khác trên Docker Desktop khác. Ba truy vấn trên đã trả log trong lần kiểm tra; xác minh lại sau khi chạy trên máy nộp.

## 8. Hardening được cấu hình
- Ứng dụng Node chạy bằng user không phải root.
- App dùng filesystem read-only và tmpfs cho `/tmp`.
- Ứng dụng và Nginx chạy bằng UID không phải root; cả hai đặt `no-new-privileges` và drop capabilities. Nginx chỉ được cấp lại `NET_BIND_SERVICE` để lắng nghe cổng 80.
- PostgreSQL nằm trong network backend nội bộ, không publish cổng ra host.
- pgAdmin, Prometheus, Grafana và Loki chỉ bind vào `127.0.0.1`.
- Mật khẩu đưa qua `.env`, file `.env` nằm trong `.gitignore`.
- Nginx có security headers và giới hạn kích thước request.

Lưu ý: cAdvisor cần quyền cao để đọc số liệu container; Promtail được mount thư mục log Docker chỉ đọc. Đây là các ngoại lệ cần nêu trong báo cáo. Mẫu dùng security headers nhưng chưa bật HTTPS.

## 9. Troubleshooting
- `DB_PASSWORD is required`: sao chép `.env.example` thành `.env` và chỉnh biến.
- Không mở được website: chạy `docker compose ps` và `docker compose logs app db nginx`.
- App chưa kết nối DB: đợi healthcheck rồi thử lại; kiểm tra `docker compose logs db app`.
- Cổng bị chiếm: đổi cổng host ở vế trái trong `ports`.
- Không có log Loki: kiểm tra `docker compose logs promtail loki`, xác nhận host có mount được `/var/lib/docker/containers` và xác minh query LogQL trong Grafana Explore.
- Exporter không `UP`: kiểm tra log exporter, quyền Docker và cấu hình exporter trên hệ điều hành.

## 10. Dọn dẹp
`docker compose down` dừng dịch vụ. `docker compose down -v` xóa cả dữ liệu volume PostgreSQL/Prometheus/Grafana/Loki; chỉ dùng khi chấp nhận mất dữ liệu.
