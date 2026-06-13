import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:xommoigarden/controller/admin_controller.dart';

class AdminStatistics extends StatefulWidget {
  const AdminStatistics({super.key});

  @override
  State<AdminStatistics> createState() => _AdminStatisticsState();
}

class _AdminStatisticsState extends State<AdminStatistics> {
  final AdminController controller = Get.find<AdminController>();

  @override
  void initState() {
    super.initState();
    if (controller.statisticsStartDate.value == null ||
        controller.statisticsEndDate.value == null) {
      controller.fetchStatisticsForPreset('this_month');
    } else {
      _refreshCurrentRange(showLoading: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Obx(() {
        if (controller.isLoadingStatistics.value &&
            controller.revenueByDay.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: _refreshCurrentRange,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildPrimaryStats(),
                const SizedBox(height: 16),
                _buildOrderStats(),
                const SizedBox(height: 16),
                _buildRevenueChart(),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildTopProducts()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTopCustomers()),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTopVouchers(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Spacer(),
        OutlinedButton.icon(
          onPressed: _showPeriodMenu,
          icon: const Icon(Icons.date_range_outlined),
          label: Text(controller.statisticsLabel.value),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Tải lại',
          onPressed: _refreshCurrentRange,
          icon: const Icon(Icons.refresh),
          style: IconButton.styleFrom(backgroundColor: Colors.white),
        ),
      ],
    );
  }

  Future<void> _refreshCurrentRange({bool showLoading = true}) async {
    final start = controller.statisticsStartDate.value;
    final end = controller.statisticsEndDate.value;
    if (start == null || end == null) {
      await controller.fetchStatisticsForPreset('this_month');
      return;
    }

    await controller.fetchStatistics(
      startDate: start,
      endDate: end,
      label: controller.statisticsLabel.value,
      showLoading: showLoading,
    );
  }

  Future<void> _showPeriodMenu() async {
    final selected = await Get.dialog<String>(
      SimpleDialog(
        title: const Text('Chọn thời gian thống kê'),
        children: [
          _periodItem('this_week', 'Tuần này'),
          _periodItem('last_week', 'Tuần trước'),
          _periodItem('this_month', 'Tháng này'),
          _periodItem('last_month', 'Tháng trước'),
          _periodItem('one_year', '1 năm'),
          const Divider(height: 1),
          SimpleDialogOption(
            onPressed: () => Get.back(result: 'custom'),
            child: const Row(
              children: [
                Icon(Icons.tune_outlined),
                SizedBox(width: 12),
                Text('Tùy chỉnh'),
              ],
            ),
          ),
        ],
      ),
    );

    if (selected == null) return;
    if (selected == 'custom') {
      await _pickCustomRange();
      return;
    }
    await controller.fetchStatisticsForPreset(selected);
  }

  SimpleDialogOption _periodItem(String value, String label) {
    return SimpleDialogOption(
      onPressed: () => Get.back(result: value),
      child: Row(
        children: [
          Icon(
            controller.statisticsLabel.value == label
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialStart =
        controller.statisticsStartDate.value ??
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
    final initialEnd = controller.statisticsEndDate.value ?? now;

    final picked = await Get.dialog<DateTimeRange>(
      _YearRangePickerDialog(
        initialStart: initialStart,
        initialEnd: initialEnd,
        initialYear: initialStart.year,
        minYear: now.year - 5,
        maxYear: now.year + 1,
      ),
    );

    if (picked == null) return;
    await controller.fetchStatistics(
      startDate: picked.start,
      endDate: picked.end,
      label: 'Tùy chỉnh',
    );
  }

  String _rangeText() {
    final start = controller.statisticsStartDate.value;
    final end = controller.statisticsEndDate.value;
    if (start == null || end == null) return controller.statisticsLabel.value;
    return '${_date(start)} - ${_date(end)}';
  }

  Widget _buildPrimaryStats() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Tổng doanh thu',
            value: _money(controller.revenueTotalAllTime.value),
            icon: Icons.payments_outlined,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Khoảng thời gian',
            value: _rangeText(),
            icon: Icons.event_available_outlined,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderStats() {
    final total = controller.statisticTotalOrders.value;
    final cancelled = controller.statisticCancelledOrders.value;
    final cancelRate = total == 0 ? 0.0 : cancelled * 100 / total;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Tổng đơn',
            value: '$total',
            icon: Icons.receipt_long_outlined,
            color: Colors.indigo,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Hoàn thành',
            value: '${controller.statisticCompletedOrders.value}',
            icon: Icons.verified_outlined,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Đơn hủy',
            value: '$cancelled (${cancelRate.toStringAsFixed(1)}%)',
            icon: Icons.cancel_outlined,
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Giá trị đơn TB',
            value: _money(controller.statisticAverageOrderValue.value),
            icon: Icons.trending_up,
            color: Colors.purple,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statCard(
            title: 'Khách mới',
            value: '${controller.statisticNewCustomers.value}',
            icon: Icons.person_add_alt_1_outlined,
            color: Colors.teal,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueChart() {
    final data = controller.revenueByDay;
    final maxRevenue = data.fold<double>(
      0,
      (max, item) =>
          (item['revenue'] as double) > max ? item['revenue'] as double : max,
    );

    return _panel(
      title: 'Doanh thu theo ${controller.statisticsLabel.value.toLowerCase()}',
      child: SizedBox(
        height: 220,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: data.map((item) {
            final revenue = item['revenue'] as double;
            final heightFactor = maxRevenue == 0 ? 0.0 : revenue / maxRevenue;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      _shortMoney(revenue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: FractionallySizedBox(
                        heightFactor: heightFactor.clamp(0.04, 1.0),
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item['label'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTopProducts() {
    final products = controller.productSalesStats.toList()
      ..sort((a, b) => (b['quantity'] as int).compareTo(a['quantity'] as int));

    return _rankPanel(
      title: 'Top sản phẩm bán chạy',
      emptyText: 'Chưa có sản phẩm bán ra',
      items: products.take(5).toList(),
      itemBuilder: (item) {
        return _rankTile(
          title: item['name'] as String,
          subtitle: 'Đã bán ${item['quantity']}',
          trailing: _money(item['revenue'] as double),
        );
      },
    );
  }

  Widget _buildTopCustomers() {
    return _rankPanel(
      title: 'Top khách hàng chi tiêu',
      emptyText: 'Chưa có khách hàng hoàn thành đơn',
      items: controller.topSpendingCustomers,
      itemBuilder: (item) {
        final phone = item['phone'] as String;
        return _rankTile(
          title: item['name'] as String,
          subtitle: '${item['orders']} đơn${phone.isEmpty ? '' : ' • $phone'}',
          trailing: _money(item['spent'] as double),
        );
      },
    );
  }

  Widget _buildTopVouchers() {
    return _rankPanel(
      title: 'Voucher được dùng nhiều nhất',
      emptyText: 'Chưa có đơn dùng voucher trong kỳ này',
      items: controller.topUsedVouchers,
      itemBuilder: (item) {
        return _rankTile(
          title: item['code'] as String,
          subtitle: '${item['orders']} đơn',
          trailing: 'Giảm ${_money(item['discount'] as double)}',
        );
      },
    );
  }

  Widget _panel({
    required String title,
    required Widget child,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ?action,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _rankPanel({
    required String title,
    required String emptyText,
    required List<Map<String, dynamic>> items,
    required Widget Function(Map<String, dynamic>) itemBuilder,
    Widget? action,
  }) {
    return _panel(
      title: title,
      action: action,
      child: items.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  emptyText,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          : Column(
              children: [
                for (var i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: i == items.length - 1 ? 0 : 10,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.green.shade50,
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: Colors.green.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: itemBuilder(items[i])),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _rankTile({
    required String title,
    required String subtitle,
    required String trailing,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          trailing,
          style: const TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.right,
        ),
      ],
    );
  }

  String _money(double value) => '${value.toStringAsFixed(0)}đ';

  String _date(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _shortMoney(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}tr';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}k';
    return value.toStringAsFixed(0);
  }
}

class _YearRangePickerDialog extends StatefulWidget {
  const _YearRangePickerDialog({
    required this.initialStart,
    required this.initialEnd,
    required this.initialYear,
    required this.minYear,
    required this.maxYear,
  });

  final DateTime initialStart;
  final DateTime initialEnd;
  final int initialYear;
  final int minYear;
  final int maxYear;

  @override
  State<_YearRangePickerDialog> createState() => _YearRangePickerDialogState();
}

class _YearRangePickerDialogState extends State<_YearRangePickerDialog> {
  static const List<String> _weekdays = [
    'Cn',
    'T2',
    'T3',
    'T4',
    'T5',
    'T6',
    'T7',
  ];

  late int _year;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    _year = widget.initialYear.clamp(widget.minYear, widget.maxYear);
    _start = _dayOnly(widget.initialStart);
    _end = _dayOnly(widget.initialEnd);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1180, maxHeight: 760),
        child: Column(
          children: [
            _buildToolbar(),
            const Divider(height: 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final columns = _columnsForWidth(constraints.maxWidth);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 12,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 24,
                        crossAxisSpacing: 42,
                        childAspectRatio: _monthAspectRatio(columns),
                      ),
                      itemBuilder: (context, index) {
                        return _buildMonth(index + 1);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final canGoBack = _year > widget.minYear;
    final canGoForward = _year < widget.maxYear;

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _goToday,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.black87,
              side: BorderSide(color: Colors.grey.shade500),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text('Hôm nay'),
          ),
          const SizedBox(width: 14),
          IconButton(
            tooltip: 'Năm trước',
            onPressed: canGoBack ? () => setState(() => _year--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            tooltip: 'Năm sau',
            onPressed: canGoForward ? () => setState(() => _year++) : null,
            icon: const Icon(Icons.chevron_right),
          ),
          const SizedBox(width: 8),
          Text(
            '$_year',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          if (_start != null)
            Flexible(
              child: Text(
                _end == null
                    ? _formatDate(_start!)
                    : '${_formatDate(_start!)} - ${_formatDate(_end!)}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Đóng',
            onPressed: () => Get.back(),
            icon: const Icon(Icons.close),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _start == null ? null : _apply,
            icon: const Icon(Icons.check),
            label: const Text('Áp dụng'),
          ),
        ],
      ),
    );
  }

  Widget _buildMonth(int month) {
    final days = _visibleDaysForMonth(_year, month);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            'Tháng $month',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            return Center(
              child: Text(
                _weekdays[index],
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
            );
          },
        ),
        Expanded(
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: days.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1.45,
            ),
            itemBuilder: (context, index) {
              return _buildDayCell(days[index], month);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDayCell(DateTime date, int visibleMonth) {
    final normalized = _dayOnly(date);
    final isCurrentMonth = normalized.month == visibleMonth;
    final isToday = DateUtils.isSameDay(normalized, DateTime.now());
    final isStart = _start != null && DateUtils.isSameDay(normalized, _start);
    final isEnd = _end != null && DateUtils.isSameDay(normalized, _end);
    final isInRange =
        _start != null &&
        _end != null &&
        normalized.isAfter(_start!) &&
        normalized.isBefore(_end!);

    Color textColor = isCurrentMonth ? Colors.black87 : Colors.grey.shade400;
    Color backgroundColor = Colors.transparent;
    BorderSide border = BorderSide.none;

    if (isInRange) {
      backgroundColor = Colors.blue.shade50;
      textColor = Colors.blue.shade900;
    }
    if (isToday) {
      border = BorderSide(color: Colors.blue.shade600);
      textColor = Colors.blue.shade700;
    }
    if (isStart || isEnd) {
      backgroundColor = Colors.blue.shade700;
      textColor = Colors.white;
      border = BorderSide.none;
    }

    return Padding(
      padding: const EdgeInsets.all(1.5),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _selectDate(normalized),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.fromBorderSide(border),
          ),
          child: Center(
            child: Text(
              '${normalized.day}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: isStart || isEnd
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectDate(DateTime date) {
    setState(() {
      if (_start == null || (_start != null && _end != null)) {
        _start = date;
        _end = null;
        return;
      }

      if (date.isBefore(_start!)) {
        _end = _start;
        _start = date;
      } else {
        _end = date;
      }
    });
  }

  void _goToday() {
    final today = _dayOnly(DateTime.now());
    setState(() {
      _year = today.year.clamp(widget.minYear, widget.maxYear);
      _start = today;
      _end = today;
    });
  }

  void _apply() {
    final start = _start!;
    final end = _end ?? _start!;
    Get.back(
      result: DateTimeRange(start: start, end: end),
    );
  }

  int _columnsForWidth(double width) {
    if (width >= 980) return 4;
    if (width >= 720) return 3;
    if (width >= 460) return 2;
    return 1;
  }

  double _monthAspectRatio(int columns) {
    if (columns >= 4) return 1.25;
    if (columns == 3) return 1.18;
    if (columns == 2) return 1.12;
    return 1.35;
  }

  List<DateTime> _visibleDaysForMonth(int year, int month) {
    final firstDay = DateTime(year, month, 1);
    final start = firstDay.subtract(Duration(days: firstDay.weekday % 7));

    return List.generate(42, (index) {
      final date = start.add(Duration(days: index));
      return DateTime(date.year, date.month, date.day);
    });
  }

  static DateTime _dayOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
