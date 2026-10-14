# BÁO CÁO THỰC HÀNH

## HỆ THỐNG QUẢN LÝ SỰ KIỆN/EVEN

**Môn học:** Triển khai và Quản trị Hệ thống Phần mềm

**Sinh viên:** Diệp Chí Vỹ

**Mã số sinh viên:** DTC245200892

**Lớp:** CNTT K23N

**Khoa:** Công nghệ thông tin

**Trường:** Trường Đại học Công nghệ Thông tin và Truyền thông

**Giảng viên hướng dẫn:** Vũ Văn Diện
**Địa điểm, năm:** Thái Nguyên, 2026

> **Hoàn thiện trước khi nộp:** Đây là bản thảo nội dung dựa trên cấu hình và các kiểm tra trong môi trường phát triển. Thêm ảnh chụp thực tế tại các vị trí `[CHÈN ẢNH ...]`, cập nhật kết quả LogQL sau khi chạy trên máy nộp, dàn trang theo mẫu của trường và kiểm tra bản xuất cuối đạt tối thiểu 10 trang. Không dùng ảnh minh họa thay cho bằng chứng.

## Mục lục

1. Giới thiệu đề tài
2. Yêu cầu và phạm vi
3. Phân tích, thiết kế kiến trúc
4. Triển khai ứng dụng và cơ sở dữ liệu
5. Reverse proxy Nginx và bảo vệ HTTP
6. Giám sát Prometheus và Grafana
7. Thu thập log bằng Loki và Promtail
8. Hardening và giới hạn bảo mật
9. Kiểm thử và đối chiếu yêu cầu
10. Kết luận và hướng phát triển
11. Phụ lục triển khai

## 1. Giới thiệu đề tài

### 1.1 Bối cảnh

Các hội thảo, workshop và ngày hội cần một nơi tập trung để công bố thông tin, theo dõi số lượng người đăng ký và quản lý số chỗ còn lại. Đề tài xây dựng ứng dụng web nhỏ để mô phỏng quy trình này, đồng thời thực hành đóng gói và vận hành nhiều dịch vụ bằng Docker Compose.

Ngoài chức năng nghiệp vụ, dự án tích hợp cơ sở dữ liệu quan hệ, reverse proxy, công cụ quản trị cơ sở dữ liệu, thu thập số liệu, dashboard, tập trung log và một số cấu hình hardening. Các dịch vụ được khai báo cùng nhau để có thể khởi chạy, kiểm tra và dừng theo một quy trình thống nhất.

### 1.2 Mục tiêu

- Quản lý danh sách sự kiện, tạo/xóa sự kiện và theo dõi lượt đăng ký.
- Ghi nhận người tham dự, kiểm tra sức chứa và cấp mã vé.
- Lưu dữ liệu trong PostgreSQL và cung cấp pgAdmin để quản trị DB.
- Đặt Nginx phía trước ứng dụng Node.js/Express làm reverse proxy.
- Giám sát ứng dụng, PostgreSQL và container bằng Prometheus/Grafana.
- Tập trung log bằng Loki/Promtail và hỗ trợ truy vấn LogQL.
- Áp dụng hardening cơ bản và lưu trữ mã nguồn trên GitHub theo ba giai đoạn.

### 1.3 Phạm vi và giới hạn

Phạm vi bao gồm quản lý sự kiện, đăng ký, mã vé, PostgreSQL, pgAdmin, proxy, metrics, logging và hardening cơ bản. Bản mẫu chưa có xác thực/phân quyền quản trị, thanh toán, gửi email vé hoặc khôi phục mật khẩu. Hiện website dùng HTTP cục bộ, chưa bật HTTPS. Không triển khai công khai trên Internet trước khi bổ sung xác thực, TLS, giới hạn truy cập, sao lưu và rà soát bảo mật.

## 2. Yêu cầu và phạm vi triển khai

### 2.1 Môi trường

- Windows với Docker Desktop và Docker Compose v2.
- Git và trình duyệt web.
- Tài nguyên máy đủ chạy PostgreSQL, Node.js, Nginx, Grafana, Prometheus, Loki, Promtail, pgAdmin, postgres-exporter và cAdvisor cùng lúc.

### 2.2 Thành phần

| Thành phần | Vai trò |
|---|---|
| Node.js/Express | Giao diện, API nghiệp vụ, health check và metrics |
| PostgreSQL | Lưu dữ liệu sự kiện và đăng ký |
| pgAdmin | Giao diện quản trị PostgreSQL |
| Nginx | Reverse proxy và security headers |
| Prometheus | Scrape metrics ứng dụng và exporter |
| Grafana | Datasource và giao diện dashboard/Explore |
| postgres-exporter | Xuất metrics PostgreSQL |
| cAdvisor | Metrics container; cần quyền host rộng |
| Promtail | Đọc file log Docker và chuyển log tới Loki |
| Loki | Lưu trữ và cung cấp truy vấn log |

## 3. Phân tích và thiết kế kiến trúc

### 3.1 Luồng xử lý

Người dùng truy cập cổng HTTP `8080` trên máy phát triển. Nginx nhận yêu cầu và chuyển tiếp đến `app:3000`. Ứng dụng truy vấn PostgreSQL thông qua mạng backend. pgAdmin kết nối tới DB để quản trị; PostgreSQL không publish cổng ra host.

Prometheus lấy số liệu từ ứng dụng tại `/metrics`, postgres-exporter và cAdvisor. Grafana được cấu hình datasource Prometheus và Loki. Promtail đọc file log Docker qua bind mount chỉ đọc và gửi tới Loki.

```text
Trình duyệt --HTTP:8080--> Nginx --frontend--> Node.js/Express:3000
                                                   |       |
                                               backend   monitoring
                                                   |       |
                                              PostgreSQL  Prometheus
                                                  ^       ^    |
                                               pgAdmin  exporters Grafana

Docker Engine --read-only log mount--> Promtail --> Loki --> Grafana Explore
```

**[CHÈN HÌNH 1: Sơ đồ kiến trúc tự vẽ, chỉ rõ dịch vụ, các mạng và hướng lưu lượng.]**

### 3.2 Mạng và cổng

Compose định nghĩa `frontend`, `backend` và `monitoring`. Backend được đặt `internal`; ứng dụng kết nối đồng thời với DB, proxy và monitoring. Các cổng host là website `8080`, pgAdmin `127.0.0.1:5050`, Prometheus `127.0.0.1:9090`, Grafana `127.0.0.1:3001` và Loki `127.0.0.1:3100`. Website bind mọi interface host; các giao diện vận hành chỉ bind loopback.

## 4. Triển khai ứng dụng và cơ sở dữ liệu

### 4.1 Mô hình dữ liệu

Bảng `events` lưu tên, địa điểm, thời gian, sức chứa, mô tả và thời điểm tạo; sức chứa phải dương. Bảng `registrations` lưu sự kiện, họ tên, email, mã vé và thời điểm tạo. Khóa ngoại `event_id` tham chiếu `events(id)`; xóa sự kiện sẽ xóa đăng ký liên quan nhờ `ON DELETE CASCADE`.

| Bảng | Trường chính | Ràng buộc |
|---|---|---|
| `events` | `id`, `name`, `location`, `event_date`, `capacity`, `description`, `created_at` | Khóa chính; trường nghiệp vụ bắt buộc; sức chứa dương |
| `registrations` | `id`, `event_id`, `attendee_name`, `attendee_email`, `ticket_code`, `created_at` | Khóa chính; khóa ngoại; mã vé duy nhất |

### 4.2 Chức năng và API

- `GET /`: hiển thị tổng số sự kiện, lượt đăng ký, form và danh sách.
- `GET /api/events`: danh sách sự kiện kèm số đăng ký.
- `POST /api/events`: tạo sự kiện; dữ liệu không hợp lệ trả HTTP 400.
- `DELETE /api/events/:id`: xóa sự kiện; không có sự kiện trả HTTP 404.
- `POST /api/events/:id/register`: kiểm tra sự kiện/sức chứa trong transaction và tạo mã vé.
- `GET /api/registrations`: danh sách đăng ký kèm tên sự kiện.
- `GET /health`: kiểm tra kết nối PostgreSQL.
- `GET /metrics`: cung cấp `even_events_total` và `even_registrations_total`.

Khi đăng ký, ứng dụng khóa dòng sự kiện bằng `FOR UPDATE` trước khi kiểm tra sức chứa nhằm tuần tự hóa các yêu cầu cạnh tranh cho cùng sự kiện. Mã vé của bản mẫu là định danh đơn giản, chưa phải vé ký số hoặc quy trình xác thực vé dùng trong sản phẩm thực tế.

### 4.3 Khởi chạy và pgAdmin

Tạo `.env` từ `.env.example`, thay mật khẩu mẫu bằng mật khẩu mạnh, riêng biệt, sau đó kiểm tra và chạy:

```powershell
Copy-Item .env.example .env
notepad .env
docker compose config
docker compose up -d --build
docker compose ps
```

pgAdmin tại `http://localhost:5050`. Khi thêm server, nhập host `db`, port `5432`, database `even_db`, user `even_app`, và giá trị `DB_PASSWORD` trong `.env`. Tài khoản pgAdmin lấy từ `PGADMIN_EMAIL` và `PGADMIN_PASSWORD`.

**[CHÈN HÌNH 2: Trang chủ ứng dụng tại localhost:8080.]**

**[CHÈN HÌNH 3: pgAdmin hiển thị kết nối DB và bảng events, registrations.]**
**[CHÈN HÌNH 4: Dữ liệu sự kiện/đăng ký sau kiểm thử; không để lộ bí mật.]**

## 5. Reverse proxy Nginx và bảo vệ HTTP

Nginx nghe cổng 80 trong container, publish ra host tại `8080`, rồi chuyển tiếp yêu cầu đến `http://app:3000`. Proxy giữ Host, chuyển địa chỉ IP và giao thức yêu cầu; timeout kết nối 5 giây, timeout đọc 30 giây. Request body bị giới hạn 1 MiB.

Các header cấu hình gồm `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer` và `Permissions-Policy` tắt camera, microphone, geolocation. Header cũng được đặt ở ứng dụng nên phản hồi có thể lặp header; có thể tinh chỉnh để chỉ thiết lập tại một lớp. Website dùng HTTP cục bộ, không có TLS và không được mô tả là HTTPS.

Lệnh xác minh:

```powershell
curl.exe -I http://localhost:8080/
```

**[CHÈN HÌNH 5: Kết quả curl -I có HTTP 200 và security headers.]**

## 6. Giám sát Prometheus và Grafana

Prometheus scrape mỗi 15 giây với bốn job: `prometheus` (`localhost:9090`), `even_app` (`app:3000/metrics`), `postgres` (`postgres-exporter:9187`) và `containers` (`cadvisor:8080`). Có thể kiểm tra tại `http://localhost:9090/targets`.

Hai metric tùy chỉnh là `even_events_total` và `even_registrations_total`. Các truy vấn gợi ý:

```promql
up
even_events_total
even_registrations_total
pg_up
sum by (id) (container_memory_usage_bytes)
```

Grafana được provision datasource Prometheus và Loki. Dashboard `Even - System Overview` được provision tự động với panels tổng sự kiện, lượt đăng ký, trạng thái scrape targets, `pg_up` và memory container. API Grafana đã xác nhận dashboard có 5 panels, cùng datasource Prometheus/Loki. Endpoint health trả database `ok`; cả bốn Prometheus target có trạng thái `up`. Chụp giao diện dashboard và trang Targets trước khi nộp.

**[CHÈN HÌNH 6: Trang Prometheus Targets với trạng thái các job.]**

**[CHÈN HÌNH 7: Grafana dashboard provisioned hiển thị các metric.]**

## 7. Thu thập log bằng Loki và Promtail

Promtail đọc các file JSON log tại `/var/lib/docker/containers/*/*-json.log`, được mount vào container ở chế độ chỉ đọc. Đường dẫn log Linux có thể khác giữa các môi trường Docker Desktop/Windows; trong môi trường kiểm tra hiện tại, Promtail nhìn thấy và đẩy được log từ đường dẫn này. Promtail gửi log tới `http://loki:3100/loki/api/v1/push`; Loki lưu trữ trên volume riêng.

Endpoint Loki `/ready` trả `ready`; ngoài ra, cả ba truy vấn LogQL dưới đây đã được chạy qua Loki API và trả log container, gồm log `event_created` và `registration_created`. Khi nộp, chụp màn hình Grafana Explore trên máy:

```logql
{job="docker"}
{job="docker"} |= "event_created"
{job="docker"} |= "registration_created"
```

Tạo sự kiện và đăng ký thử, chờ log được đẩy, sau đó tìm trong khoảng thời gian tương ứng. Nếu máy khác không thấy stream, kiểm tra `docker compose logs promtail loki` và xác minh host có mount được đường dẫn log.

**[CHÈN HÌNH 8: Grafana Explore với query `{job="docker"}` và log thực tế.]**

**[CHÈN HÌNH 9: Query lọc event_created hoặc registration_created có kết quả.]**

## 8. Hardening và giới hạn bảo mật

Các biện pháp được cấu hình: ứng dụng chạy user `node`, Nginx chạy UID/GID `101:101`; filesystem app/Nginx read-only; app và Nginx có `no-new-privileges` và drop capabilities; Nginx chỉ được cấp lại `NET_BIND_SERVICE` để bind cổng 80; app dùng tmpfs cho `/tmp`, Nginx dùng tmpfs có quyền sở hữu phù hợp cho cache/runtime; backend network internal; DB không publish cổng host; giao diện quản trị bind loopback; mật khẩu riêng, mạnh được lưu trong `.env` cục bộ và `.env` nằm trong `.gitignore`; Nginx giới hạn body request và thêm security headers; DB healthcheck giúp app đợi DB sẵn sàng.

Các ngoại lệ cần nêu rõ:

- cAdvisor chạy `privileged: true`, dùng `/dev/kmsg` và bind mount host để đọc số liệu. Đây là quyền rộng, chỉ phù hợp môi trường thực hành.
- Promtail được cấp quyền đọc các file log Docker qua bind mount chỉ đọc; đường dẫn host có thể khác trên máy khác.
- Nginx được chạy trực tiếp dưới UID/GID không phải root, bỏ entrypoint mặc định và chỉ được cấp lại `NET_BIND_SERVICE`. Cấu hình dùng tmpfs có UID/GID phù hợp cho cache và runtime.
- HTTP chưa có HTTPS; website chưa có xác thực/phân quyền quản trị.

**[CHÈN HÌNH 10: Trích cấu hình hardening từ Compose; che toàn bộ mật khẩu.]**

## 9. Kiểm thử và đối chiếu yêu cầu

### 9.1 Ma trận kiểm thử

| Mã | Kiểm thử | Kết quả quan sát | Bằng chứng |
|---|---|---|---|
| T01 | Mở trang chủ `localhost:8080` | Pass: HTTP 200 và giao diện tải được | Hình trang chủ |
| T02 | `GET /health` | Pass: DB connected | Hình/copy kết quả |
| T03 | `curl -I` qua Nginx | Pass: status 200 và headers đã cấu hình | Hình curl |
| T04 | Prometheus targets | Pass ở lần kiểm tra: app, postgres exporter, containers, Prometheus `up` | Hình Targets |
| T05 | Grafana health | Pass ở lần kiểm tra: database `ok` | Hình health/datasource |
| T06 | Loki readiness | Pass ở lần kiểm tra: `/ready` trả `ready` | Hình/lệnh |
| T07 | Tạo sự kiện hợp lệ | Pass: API trả HTTP 201; sự kiện kiểm thử đã được xóa | Hình UI/API |
| T08 | Tạo sự kiện thiếu dữ liệu | Pass: HTTP 400 | Hình API |
| T09 | Đăng ký và nhận mã vé | Pass: API trả đăng ký và mã vé; dữ liệu kiểm thử đã được xóa | Hình UI/API/DB |
| T10 | Đăng ký quá sức chứa | Pass: HTTP 409 với sự kiện sức chứa 1 | Hình API |
| T11 | LogQL xem log container | Pass: query tổng quát và hai query lọc event/registration trả log | Hình Explore |
| T12 | Kiểm tra `.env` không trong Git | Được loại bởi `.gitignore`; kiểm tra lại trước khi nộp | Hình git status |

Các kết quả Pass ở đây là kiểm thử API/endpoint thực tế trong môi trường phát triển. Cần chèn ảnh làm bằng chứng; dashboard, giao diện LogQL và các dịch vụ phải được kiểm tra lại trên máy trình diễn.

### 9.2 Đối chiếu từng yêu cầu đề bài

| Yêu cầu | Trạng thái | Ghi chú cuối |
|---|---|---|
| Mã nguồn/cấu hình trên GitHub, README rõ | Có | Repo đã có; xác minh thay đổi mới nhất được push |
| Website, Database, công cụ quản lý DB chạy bằng Compose | Đạt ở lần kiểm tra | App, PostgreSQL, pgAdmin |
| Nginx reverse proxy: HTTPS tự ký hoặc security headers | Đạt theo nhánh headers | HTTP, không có HTTPS |
| Prometheus + Grafana giám sát container, web, DB | Đạt: 4 targets `up`, dashboard 5 panels đã provision | Chụp dashboard và Targets |
| Loki + Promtail, 2–3 truy vấn LogQL | Đạt trên máy phát triển: 3 query trả log qua Loki API | Chụp Explore; xác minh đường dẫn trên máy nộp |
| Hardening: non-root, isolation, secrets, headers | Đạt một phần, có ngoại lệ | Nêu cAdvisor, thư mục log, Nginx capabilities |
| Báo cáo tối thiểu 10 trang có bìa và hình | Bản thảo nội dung đã có | Chèn hình thật, xuất PDF, kiểm tra đủ trang |

### 9.3 GitHub và ba giai đoạn commit

Repository: <https://github.com/dtc245200892-jpg/he-thong-quan-ly-su-kien-even>

1. `commit 1: deploy app database and nginx reverse proxy`
2. `commit 2: add prometheus grafana monitoring`
3. `commit 3: add loki promtail logging and hardening`

Không commit `.env` hoặc ảnh có mật khẩu/token. Sau khi hoàn thiện thay đổi cuối, xác minh `git status`, push rồi chụp lịch sử ba commit trên GitHub.

**[CHÈN HÌNH 11: GitHub repository và lịch sử ba commit.]**

## 10. Kết luận và hướng phát triển

Đề tài đã tạo bộ triển khai nhiều container cho hệ thống quản lý sự kiện/Even. Ứng dụng kết nối PostgreSQL; Nginx làm reverse proxy và thêm security headers; Prometheus scrape ứng dụng và exporter; Grafana provision datasource và dashboard; Loki/Promtail đã trả log thực tế qua LogQL. Một số hardening được áp dụng, đồng thời các ngoại lệ quyền cAdvisor và truy cập thư mục log Docker đã được nhận diện.

Trước khi nộp cần hoàn tất ảnh thật, chụp dashboard Grafana và các query LogQL, xác minh thay đổi cuối đã push, dàn trang/kiểm đếm tối thiểu 10 trang. Không khẳng định HTTPS hoặc xác thực quản trị vì hai tính năng này chưa được triển khai.

Hướng phát triển: xác thực và phân quyền; sửa sự kiện; chống đăng ký trùng email; mã QR vé có cơ chế xác minh; TLS; backup/restore; dashboard/alerts; CI/CD; và giảm quyền container trước khi công khai.

## 11. Phụ lục triển khai

### 11.1 Cấu trúc repository

```text
even_project/
  app/                  Node.js/Express và Dockerfile
  db/                   SQL tham khảo
  nginx/                Reverse proxy và security headers
  prometheus/            Cấu hình scrape
  grafana/provisioning/  Datasource Prometheus và Loki
  loki/                  Cấu hình lưu trữ log
  promtail/              Docker discovery và chuyển log
  docker-compose.yml     Services, networks, volumes, hardening
  .env.example           Mẫu biến môi trường
  README.md              Hướng dẫn chạy
  REPORT_OUTLINE.md      Dàn ý
  REPORT.md              Bản thảo báo cáo
```

### 11.2 Lệnh kiểm tra

```powershell
docker compose config
docker compose up -d --build
docker compose ps
curl.exe http://localhost:8080/health
curl.exe http://localhost:8080/api/events
curl.exe -I http://localhost:8080/
curl.exe http://localhost:8080/metrics
docker compose logs --tail=100 app nginx promtail loki
```

`docker compose down` dừng dịch vụ. `docker compose down -v` xóa cả dữ liệu volumes PostgreSQL và monitoring/log; chỉ dùng khi chấp nhận mất dữ liệu.

### 11.3 Danh sách ảnh cần chèn

1. Bìa theo mẫu của trường.
2. Sơ đồ kiến trúc, dịch vụ và mạng.
3. `docker compose ps`.
4. Trang web.
5. pgAdmin và hai bảng.
6. `curl -I` và security headers.
7. Prometheus Targets.
8. Grafana datasource/dashboard có số liệu.
9. Grafana Explore với 2–3 truy vấn LogQL.
10. Cấu hình hardening không lộ bí mật.
11. GitHub repo và lịch sử ba commit.

Ảnh phải lấy từ hệ thống do sinh viên chạy; che thông tin xác thực và dữ liệu cá nhân không cần thiết.
