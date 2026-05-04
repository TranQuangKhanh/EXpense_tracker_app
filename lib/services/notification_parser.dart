class ParsedTransaction {
  final double amount;
  final String type;
  final String bankName;
  final String title;
  final String suggestedCategoryId;

  ParsedTransaction({
    required this.amount,
    required this.type,
    required this.bankName,
    required this.title,
    required this.suggestedCategoryId,
  });
}

class NotificationParser {
  static const Map<String, String> bankPackages = {
    'com.VCB': 'Vietcombank',
    'com.vcb': 'Vietcombank',
    'vn.com.vcb': 'Vietcombank',
    'com.vcb.digibank': 'Vietcombank',
    'com.vietcombank': 'Vietcombank',
    'com.bidv.smartbanking': 'BIDV',
    'com.bidv': 'BIDV',
    'vn.bidv': 'BIDV',
    'com.techcombank.mb.app': 'Techcombank',
    'com.techcombank': 'Techcombank',
    'vn.techcombank': 'Techcombank',
    'com.mbmobile': 'MBBank',
    'com.mb.mbanking': 'MBBank',
    'vn.com.mb': 'MBBank',
    'com.vietinbank.ipay': 'Vietinbank',
    'vn.vietinbank': 'Vietinbank',
    'com.vietinbank': 'Vietinbank',
    'com.agribank': 'Agribank',
    'vn.agribank': 'Agribank',
    'com.agribank.ebanking': 'Agribank',
    'com.tpb.mb.gprs': 'TPBank',
    'com.tpbank': 'TPBank',
    'vn.tpbank': 'TPBank',
    'com.acb.mobile': 'ACB',
    'com.acb': 'ACB',
    'vn.acb': 'ACB',
    'com.sacombank': 'Sacombank',
    'vn.sacombank': 'Sacombank',
    'com.sacombank.mbanking': 'Sacombank',
    'com.vpbank': 'VPBank',
    'vn.vpbank': 'VPBank',
    'com.vpbank.neobank': 'VPBank',
    'com.hdbank': 'HDBank',
    'vn.hdbank': 'HDBank',
    'com.ocb': 'OCB',
    'vn.ocb.omni': 'OCB',
    'com.shb': 'SHB',
    'vn.shb.mobile': 'SHB',
    'com.eximbank': 'Eximbank',
    'vn.eximbank': 'Eximbank',
    'com.seabank': 'SeABank',
    'vn.seabank': 'SeABank',
    'com.mservice.momotransfer': 'MoMo',
    'com.mservice.omni': 'MoMo',
    'com.mservice': 'MoMo',
    'vn.momo.client': 'MoMo',
    'vn.momo': 'MoMo',
    'com.momo': 'MoMo',
    'vn.com.zalopay': 'ZaloPay',
    'com.zalopay': 'ZaloPay',
    'vn.zalopay': 'ZaloPay',
    'com.zing.zalopay': 'ZaloPay',
    'com.vnpay.hdbank': 'VNPay',
    'com.vnpay': 'VNPay',
    'vn.vnpay': 'VNPay',
    'vn.com.vnpay': 'VNPay',
    'com.vnpay.wallet': 'VNPay',
    'com.viettelpay': 'ViettelPay',
    'vn.viettelpay': 'ViettelPay',
    'com.viettel.pay': 'ViettelPay',
    'vn.viettel.money': 'ViettelMoney',
    'com.shopee.vn': 'ShopeePay',
    'vn.shopee': 'ShopeePay',
    'com.shopeepay': 'ShopeePay',
    'com.grabtaxi.passenger': 'GrabPay',
    'com.grab': 'GrabPay',
    'vn.payoo': 'Payoo',
    'com.payoo': 'Payoo',
    'com.vnptpay': 'VNPTPay',
    'vn.vnptpay': 'VNPTPay',
    'com.moca': 'Moca',
    'vn.moca': 'Moca',
  };

  // ✅ Fix 3 — Sắp xếp từ khóa chi tiết lên TRƯỚC từ khóa chung
  // Dùng List thay Map để giữ thứ tự ưu tiên
  static const List<MapEntry<String, String>> merchantCategoriesList = [
    // Grab — chi tiết trước, chung sau
    MapEntry('grabfood', 'food'),
    MapEntry('grabbike', 'transport'),
    MapEntry('grabcar', 'transport'),
    MapEntry('grabexpress', 'transport'),
    MapEntry('grab', 'transport'), // fallback Grab → transport

    // Shopee — chi tiết trước
    MapEntry('shopeefood', 'food'),
    MapEntry('shopee', 'shopping'),

    // Ăn uống
    MapEntry('baemin', 'food'),
    MapEntry('gofood', 'food'),
    MapEntry('circle k', 'food'),
    MapEntry('ministop', 'food'),
    MapEntry('gs25', 'food'),
    MapEntry('kfc', 'food'),
    MapEntry('mcdonalds', 'food'),
    MapEntry('jollibee', 'food'),
    MapEntry('popeyes', 'food'),
    MapEntry('highlands', 'food'),
    MapEntry('phuc long', 'food'),
    MapEntry('the coffee house', 'food'),
    MapEntry('starbucks', 'food'),
    MapEntry('cong caphe', 'food'),
    MapEntry('pizza hut', 'food'),
    MapEntry('dominos', 'food'),
    MapEntry('pizza', 'food'),
    MapEntry('lotte mart', 'shopping'), // lotte mart trước lotte cinema
    MapEntry('lotte cinema', 'entertainment'),
    MapEntry('lotte', 'food'),
    MapEntry('com tam', 'food'),
    MapEntry('banh mi', 'food'),
    MapEntry('tra sua', 'food'),
    MapEntry('gong cha', 'food'),
    MapEntry('tocotoco', 'food'),
    MapEntry('dingtea', 'food'),
    MapEntry('nha hang', 'food'),
    MapEntry('quan an', 'food'),
    MapEntry('an uong', 'food'),

    // Di chuyển
    MapEntry('gojek', 'transport'),
    MapEntry('xanh sm', 'transport'),
    MapEntry('vinbus', 'transport'),
    MapEntry('taxi', 'transport'),
    MapEntry('petrolimex', 'transport'),
    MapEntry('pvoil', 'transport'),
    MapEntry('xang ', 'transport'),
    MapEntry('parking', 'transport'),
    MapEntry('gui xe', 'transport'),
    MapEntry('ve may bay', 'transport'),
    MapEntry('vietjet', 'transport'),
    MapEntry('bamboo airways', 'transport'),
    MapEntry('vietnam airlines', 'transport'),
    MapEntry('ve xe', 'transport'),

    // Mua sắm
    MapEntry('lazada', 'shopping'),
    MapEntry('tiki', 'shopping'),
    MapEntry('sendo', 'shopping'),
    MapEntry('winmart', 'shopping'),
    MapEntry('coopmart', 'shopping'),
    MapEntry('mega market', 'shopping'),
    MapEntry('aeon', 'shopping'),
    MapEntry('ikea', 'shopping'),
    MapEntry('uniqlo', 'shopping'),
    MapEntry('zara', 'shopping'),
    MapEntry('h&m', 'shopping'),
    MapEntry('muji', 'shopping'),
    MapEntry('watsons', 'shopping'),

    // Giải trí
    MapEntry('netflix', 'entertainment'),
    MapEntry('spotify', 'entertainment'),
    MapEntry('youtube premium', 'entertainment'),
    MapEntry('cgv', 'entertainment'),
    MapEntry('bhd', 'entertainment'),
    MapEntry('galaxy cinema', 'entertainment'),
    MapEntry('steam', 'entertainment'),
    MapEntry('game ', 'entertainment'),

    // Sức khỏe
    MapEntry('pharmacity', 'health'),
    MapEntry('long chau', 'health'),
    MapEntry('an khang', 'health'),
    MapEntry('guardian', 'health'),
    MapEntry('benh vien', 'health'),
    MapEntry('phong kham', 'health'),
    MapEntry('nha thuoc', 'health'),
    MapEntry('gym', 'health'),
    MapEntry('yoga', 'health'),

    // Hóa đơn
    MapEntry('evn', 'bills'),
    MapEntry('dien luc', 'bills'),
    MapEntry('tien dien', 'bills'),
    MapEntry('tien nuoc', 'bills'),
    MapEntry('vnpt', 'bills'),
    MapEntry('viettel', 'bills'),
    MapEntry('mobifone', 'bills'),
    MapEntry('vinaphone', 'bills'),
    MapEntry('fpt telecom', 'bills'),
    MapEntry('internet', 'bills'),
    MapEntry('hoa don', 'bills'),

    // Học tập
    MapEntry('hoc phi', 'education'),
    MapEntry('duolingo', 'education'),
    MapEntry('coursera', 'education'),
    MapEntry('udemy', 'education'),
    MapEntry('sach ', 'education'),

    // Thu nhập
    MapEntry('luong', 'salary'),
    MapEntry('salary', 'salary'),
    MapEntry('thuong', 'bonus'),
    MapEntry('bonus', 'bonus'),
    MapEntry('thu nhap', 'salary'),
  ];

  static bool isFromBank(String packageName) {
    return bankPackages.keys.any(
      (pkg) => packageName.toLowerCase().contains(pkg.toLowerCase()),
    );
  }

  static String getBankName(String packageName) {
    for (final entry in bankPackages.entries) {
      if (packageName.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return 'Ngân hàng';
  }

  // ✅ Fix 3 — Dùng List để giữ thứ tự ưu tiên
  static String _suggestCategory(String text, String type) {
    final lowerText = text.toLowerCase();
    for (final entry in merchantCategoriesList) {
      if (lowerText.contains(entry.key)) {
        return entry.value;
      }
    }
    return type == 'income' ? 'other_income' : 'other_expense';
  }

  // ✅ Fix 1 — Ưu tiên số tiền có dấu +/- hoặc xuất hiện trước "số dư"
  // ✅ Fix 2 — Chuẩn hóa khoảng trắng unicode trước khi parse
  static double? _parseAmount(String rawText) {
    // Chuẩn hóa tất cả loại khoảng trắng unicode
    final text = rawText
        .replaceAll('\u00A0', ' ') // non-breaking space
        .replaceAll('\u202F', ' ') // narrow no-break space
        .replaceAll('\u2009', ' ') // thin space
        .replaceAll('\u2007', ' ') // figure space
        .toLowerCase();

    // Regex bắt số tiền
    final amountRegex = RegExp(
      r'([+\-]?\s*\d{1,3}(?:[.,]\d{3})*|\d+)\s*(?:vnd|vnđ|đồng|dong|đ[^a-z]|đ$)',
      caseSensitive: false,
    );

    // Tìm vị trí "số dư" trong text để tách phần giao dịch
    final soduKeywords = [
      'số dư', 'so du', 'sd:', 'số dư hiện tại',
      'balance', 'available balance',
    ];

    // Cắt text tại vị trí "số dư" — chỉ lấy phần trước
    String transactionText = text;
    for (final keyword in soduKeywords) {
      final idx = text.indexOf(keyword);
      if (idx > 0) {
        transactionText = text.substring(0, idx);
        break;
      }
    }

    // Ưu tiên 1: Tìm số tiền có dấu +/- trong phần transaction
    final signedRegex = RegExp(
      r'([+\-]\s*\d{1,3}(?:[.,]\d{3})*|\d+)\s*(?:vnd|vnđ|đồng|dong|đ[^a-z]|đ$)',
      caseSensitive: false,
    );

    for (final match in signedRegex.allMatches(transactionText)) {
      final raw = match
          .group(1)!
          .replaceAll(RegExp(r'[+\-\s]'), '')
          .replaceAll('.', '')
          .replaceAll(',', '');
      final amount = double.tryParse(raw);
      if (amount != null && amount >= 1000) return amount;
    }

    // Ưu tiên 2: Lấy số tiền đầu tiên trong phần transaction
    for (final match in amountRegex.allMatches(transactionText)) {
      final raw = match
          .group(1)!
          .replaceAll(RegExp(r'[+\-\s]'), '')
          .replaceAll('.', '')
          .replaceAll(',', '');
      final amount = double.tryParse(raw);
      if (amount != null && amount >= 1000) return amount;
    }

    // Fallback: tìm trong toàn bộ text, lấy số nhỏ nhất >= 1000
    // (số tiền giao dịch thường nhỏ hơn số dư)
    double? minAmount;
    for (final match in amountRegex.allMatches(text)) {
      final raw = match
          .group(1)!
          .replaceAll(RegExp(r'[+\-\s]'), '')
          .replaceAll('.', '')
          .replaceAll(',', '');
      final amount = double.tryParse(raw);
      if (amount != null && amount >= 1000) {
        if (minAmount == null || amount < minAmount) {
          minAmount = amount;
        }
      }
    }
    return minAmount;
  }

  static ParsedTransaction? parse(
      String packageName, String title, String body) {
    if (!isFromBank(packageName)) return null;

    // ✅ Fix 2 — Chuẩn hóa unicode trước khi xử lý
    final normalizedTitle = title
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ')
        .replaceAll('\u2009', ' ');
    final normalizedBody = body
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u202F', ' ')
        .replaceAll('\u2009', ' ');

    final text = '$normalizedTitle $normalizedBody'.toLowerCase();
    final bankName = getBankName(packageName);

    final amount = _parseAmount(text);
    if (amount == null || amount <= 0) return null;

    final incomeKeywords = [
      'nhận', 'nhan',
      'cộng', 'cong',
      'tiền về', 'tien ve',
      'về ví', 've vi',
      'vào ví', 'vao vi',
      'vào tài khoản', 'vao tai khoan',
      'chuyển đến', 'chuyen den',
      'received', 'credit',
      'số dư tăng', 'so du tang',
      'nhan tien chuyen khoan',
      'nhan tien tu',
    ];

    final expenseKeywords = [
      'thanh toán', 'thanh toan',
      'trừ', 'tru',
      'chuyển đi', 'chuyen di',
      'rút', 'rut',
      'debit', 'payment',
      'chi tiêu', 'chi tieu',
      'số dư giảm', 'so du giam',
      'đã trừ', 'da tru',
      'đã thanh toán', 'da thanh toan',
    ];

    String type = 'expense';
    if (incomeKeywords.any((k) => text.contains(k))) {
      type = 'income';
    } else if (expenseKeywords.any((k) => text.contains(k))) {
      type = 'expense';
    }

    final suggestedCategoryId = _suggestCategory(text, type);

    return ParsedTransaction(
      amount: amount,
      type: type,
      bankName: bankName,
      title: '$bankName - ${type == 'income' ? 'Tiền vào' : 'Tiền ra'}',
      suggestedCategoryId: suggestedCategoryId,
    );
  }
}