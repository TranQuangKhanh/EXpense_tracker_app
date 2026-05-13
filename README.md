# Expense Tracker App

Ứng dụng quản lý chi tiêu cá nhân với tính năng
tự động nhận giao dịch từ thông báo ngân hàng.

## Tính năng chính

- Thu/chi cá nhân theo danh mục
- Tự động ghi nhận giao dịch từ ngân hàng/ví điện tử
- Thống kê theo tháng
- Quản lý nhiều nguồn tiền
- Nhóm chi tiêu chung
- Đăng nhập lại bằng số điện thoại

## Ngân hàng hỗ trợ

MoMo, Vietcombank, MBBank, Techcombank, BIDV,
Agribank, TPBank, VPBank, ACB, Sacombank,
Vietinbank, SHB, ZaloPay, ShopeePay, VNPay,
GrabPay, ViettelPay

## Setup

1. Clone repo
2. Tạo Firebase project
3. Thêm `google-services.json` vào `android/app/`
4. Tạo `lib/firebase_options.dart`
5. `flutter pub get`
6. `cd android && gradlew assembleDebug`

## Tech stack

- Flutter + Dart
- Firebase (Firestore, Auth)
- Kotlin (NotificationListenerService)
