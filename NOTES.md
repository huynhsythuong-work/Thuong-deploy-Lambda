# Implementation Notes

## Hướng triển khai

Mình chọn hướng giữ nguyên Express app và thêm một lớp adapter mỏng cho Lambda:

```text
API Gateway HTTP API -> Lambda -> serverless-http -> Express app
```

`app.js` không phụ thuộc AWS. File này vẫn là Express app bình thường và được dùng lại cho cả local server lẫn Lambda.

## Thay đổi đã làm

- Thêm `serverless-http` vào dependency.
- Thêm `lambda.js` để export `handler`.
- Dùng `Handler: lambda.handler` trong `template.yaml`.
- Bỏ `FunctionName` cố định để CloudFormation tự sinh tên Lambda.
- Dùng `deploy.ps1` để package và deploy bằng AWS CLI.
- Đổi stack đang dùng sang `thuong-byol-node-express`.

## Vì sao dùng `serverless-http`

Lựa chọn này đủ gọn cho bài Express hiện tại:

- không phải sửa route trong `app.js`
- vẫn chạy local bằng `server.js`
- mapping request/response do thư viện xử lý
- dễ đọc hơn so với tự viết adapter thủ công
- không cần thêm Lambda Web Adapter layer

## Thông tin deploy hiện tại

```text
AWS account: 072937283954
Region: us-west-2
Stack: thuong-byol-node-express
API: https://4b1x0tqgf6.execute-api.us-west-2.amazonaws.com
Status: UPDATE_COMPLETE
```

Resource quan trọng sau deploy:

```text
Lambda: thuong-byol-node-express-ExpressFunction-0qmVLeiVgWMN
Log group: /aws/lambda/thuong-byol-node-express-ExpressFunction-0qmVLeiVgWMN
```

## Kiểm tra đã chạy

Endpoint root sau deploy trả về:

```json
{"ok":true,"runtime":"express","message":"hello from your existing app"}
```

Lệnh deploy đã chạy thành công bằng:

```powershell
.\deploy.ps1 -StackName thuong-byol-node-express -Region us-west-2
```

## Ghi chú tránh đụng tên

Không nên đặt `FunctionName`, `RoleName`, `BucketName` cố định trong template nếu nhiều người dùng chung AWS account. Stack name có thể khác nhau, nhưng tên resource cố định vẫn có thể gây lỗi khi deploy.

Trong repo này:

- Lambda để CloudFormation tự đặt tên.
- API Gateway để CloudFormation tự đặt tên.
- Log group đi theo tên Lambda generated.
- S3 artifact bucket trong `deploy.ps1` có account ID và region trong tên.

Điểm còn phải tự chú ý: `samconfig.toml` là cấu hình tĩnh. Nếu người khác dùng `sam deploy`, họ nên đổi `stack_name` trước.
