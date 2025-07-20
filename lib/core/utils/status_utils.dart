const Map<String, String> bookingStatusLabels = {
  'pending_admin_approval': 'قيد المراجعة',
  'approved': 'موافق عليه',
  'rejected': 'مرفوض',
  'deposit_paid': 'دفع العربون',
  'completed': 'مكتمل',
  'cancelled': 'ملغي',
  'scheduled': 'مجدول',
};

const Map<String, String> eventStatusLabels = {
  'scheduled': 'مجدول',
  'ongoing': 'قيد التنفيذ',
  'completed': 'مكتمل',
  'cancelled': 'ملغي',
};

String getBookingStatusLabel(String status) {
  return bookingStatusLabels[status] ?? status;
}

String getEventStatusLabel(String status) {
  return eventStatusLabels[status] ?? status;
}
