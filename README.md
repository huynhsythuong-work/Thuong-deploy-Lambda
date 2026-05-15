# Express Lambda Demo

Repo này đóng gói một Express app chạy được cả local và trên AWS Lambda. Phần Express nằm trong `app.js`; Lambda chỉ dùng thêm `lambda.js` để chuyển request từ API Gateway sang Express thông qua `serverless-http`.

## Thành phần chính

```text
app.js          Express app và route chính
server.js       entrypoint để chạy local bằng Node
lambda.js       handler cho AWS Lambda
template.yaml   SAM/CloudFormation template
deploy.ps1      script package và deploy bằng AWS CLI
samconfig.toml  cấu hình khi deploy bằng SAM CLI
```

Các route đang có:

- `GET /`
- `GET /api/hello/:name`
- `POST /api/echo`

## Chuẩn bị

Cần có:

- Node.js 22+
- npm
- PowerShell
- AWS CLI v2 đã login
- AWS account có quyền tạo S3, CloudFormation, Lambda, API Gateway, CloudWatch Logs và IAM role

Kiểm tra nhanh:

```powershell
node -v
npm -v
aws --version
aws sts get-caller-identity
```

Nếu AWS CLI chưa có credentials:

```powershell
aws configure
```

Region nên dùng cho bài này là:

```text
us-west-2
```

## Chạy local

Cài dependency:

```powershell
npm install
```

Start server:

```powershell
npm start
```

Test:

```powershell
curl http://localhost:3000/
curl http://localhost:3000/api/hello/Thuong
curl -Method POST http://localhost:3000/api/echo `
  -ContentType 'application/json' `
  -Body '{"source":"local"}'
```

## Deploy

Cách khuyến nghị là dùng script PowerShell:

```powershell
.\deploy.ps1
```

Nếu không truyền `-StackName`, script tự tạo tên stack theo Windows username:

```text
<username>-byol-node-express
```

Tên này giúp tránh đụng stack/Lambda của người khác trong cùng AWS account. Muốn chỉ định rõ tên stack thì chạy:

```powershell
.\deploy.ps1 -Region us-west-2 -StackName thuong-byol-node-express
```

Script sẽ:

1. lấy AWS account ID hiện tại
2. tạo S3 bucket để chứa artifact nếu chưa có
3. package template và source code
4. deploy CloudFormation stack
5. in ra API Gateway URL

Deploy hiện tại của repo này:

```text
Stack: thuong-byol-node-express
Region: us-west-2
API: https://4b1x0tqgf6.execute-api.us-west-2.amazonaws.com
```

## Test sau deploy

Lấy API URL từ CloudFormation:

```powershell
$API = aws cloudformation describe-stacks `
  --stack-name thuong-byol-node-express `
  --region us-west-2 `
  --query "Stacks[0].Outputs[?OutputKey=='ApiUrl'].OutputValue" `
  --output text
```

Gọi thử:

```powershell
curl $API
curl "$API/api/hello/Thuong"
curl -Method POST "$API/api/echo" `
  -ContentType 'application/json' `
  -Body '{"source":"lambda"}'
```

## Tránh lỗi trùng resource

Trong `template.yaml` không đặt `FunctionName` cố định. CloudFormation sẽ tự sinh tên Lambda dựa trên stack, nên nhiều người có thể deploy cùng template mà không tranh nhau Lambda tên `byol-node-express`.

Nếu dùng `sam deploy`, xem lại `samconfig.toml` trước khi chạy. File hiện đang dùng:

```text
stack_name = "thuong-byol-node-express"
region = "us-west-2"
```

Người khác copy repo nên đổi `stack_name` sang tên riêng của họ.

## Xóa hạ tầng

```powershell
aws cloudformation delete-stack `
  --stack-name thuong-byol-node-express `
  --region us-west-2
```

Nếu lúc deploy dùng stack name khác thì thay đúng tên stack đó.

## Lỗi thường gặp

`AWS::EarlyValidation::ResourceExistenceCheck`: thường do đặt tên resource cố định đã tồn tại, ví dụ Lambda `FunctionName`. Template hiện đã bỏ `FunctionName` để tránh lỗi này.

`Unable to locate credentials`: AWS CLI chưa login hoặc profile không đúng. Chạy `aws configure` hoặc kiểm tra lại `AWS_PROFILE`.

`AccessDenied`: IAM user/role thiếu quyền tạo hoặc cập nhật S3, CloudFormation, Lambda, API Gateway, CloudWatch Logs hoặc IAM.

`502 Bad Gateway`: kiểm tra `lambda.js`, dependency `serverless-http`, và `Handler: lambda.handler` trong `template.yaml`.
