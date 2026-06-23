import '../repositories/dashboard_repository.dart';

class Storyteller {
  static String analyzeGeneralTrend(List<AttendanceTrendData> data, String groupByStr) {
    if (data.isEmpty) return "لا توجد بيانات حضور كافية لتحليلها.";
    if (data.length == 1) return "تم تسجيل حضور في فترة واحدة فقط، بانتظار مزيد من البيانات.";

    final last = data.last;
    final previous = data[data.length - 2];
    
    int diff = last.count - previous.count;
    String trend = diff > 0 ? "في تزايد" : (diff < 0 ? "في تناقص" : "مستقر");
    
    AttendanceTrendData maxData = data.reduce((curr, next) => curr.count > next.count ? curr : next);
    
    String periodName = groupByStr == 'day' ? 'اليوم' : (groupByStr == 'month' ? 'الشهر' : 'السنة');

    String message = "معدل الحضور $trend مؤخراً. ";
    if (diff > 0) {
      message += "هناك زيادة بمقدار $diff حالة حضور مقارنة بـ $periodName السابق. ";
    } else if (diff < 0) {
      message += "هناك انخفاض بمقدار ${diff.abs()} حالة उपस्थिति مقارنة بـ $periodName السابق. ";
    }
    String dateStr = "";
    if (groupByStr == 'year') {
      dateStr = '${maxData.date.year}';
    } else if (groupByStr == 'month') {
      dateStr = '${maxData.date.month}/${maxData.date.year}';
    } else {
      dateStr = '${maxData.date.year}/${maxData.date.month}/${maxData.date.day}';
    }
    
    message += "أعلى معدل حضور كان بتاريخ $dateStr بعدد ${maxData.count}.";
    
    return message.replaceAll('حالة उपस्थिति', 'حالة حضور');
  }

  static String analyzeIndividualTrend(List<AttendanceTrendData> data, String name, String groupByStr) {
    if (data.isEmpty) return "لم يتم تسجيل أي حضور لـ $name حتى الآن.";
    if (data.length == 1) return "$name حضر مرة واحدة فقط، بانتظار استمراره.";

    final last = data.last;
    final previous = data[data.length - 2];
    
    int diff = last.count - previous.count;
    
    AttendanceTrendData maxData = data.reduce((curr, next) => curr.count > next.count ? curr : next);
    
    String periodName = groupByStr == 'day' ? 'اليوم' : (groupByStr == 'month' ? 'الشهر' : 'السنة');

    String status = "";
    if (diff > 0) {
      status = "انتظام $name في تحسن ملحوظ مؤخراً.";
    } else if (diff < 0) {
      status = "بدأ حضور $name يقل في $periodName الأخير.";
    } else {
      status = "حضور $name مستقر نسبياً.";
    }
    String dateStr = "";
    if (groupByStr == 'year') {
      dateStr = '${maxData.date.year}';
    } else if (groupByStr == 'month') {
      dateStr = '${maxData.date.month}/${maxData.date.year}';
    } else {
      dateStr = '${maxData.date.year}/${maxData.date.month}/${maxData.date.day}';
    }
    
    String message = "$status أكثر فترة تواجد فيها كانت بتاريخ $dateStr بواقع ${maxData.count} مرات.";
    return message;
  }

  static String analyzeDemographics(List<DemographicStatData> data, String categoryName) {
    if (data.isEmpty) return "لا توجد بيانات كافية عن $categoryName.";
    if (data.length == 1) return "جميع المسجلين ينتمون إلى تصنيف واحد: ${data.first.label}.";

    DemographicStatData maxData = data.reduce((curr, next) => curr.count > next.count ? curr : next);
    DemographicStatData minData = data.reduce((curr, next) => curr.count < next.count ? curr : next);
    
    double avg = data.map((e) => e.count).reduce((a, b) => a + b) / data.length;

    return "الأكثر عدداً هي '${maxData.label}' بـ ${maxData.count} شخص، والأقل هي '${minData.label}' بـ ${minData.count} شخص. المتوسط تقريباً ${avg.toInt()} شخص لكل $categoryName.";
  }
}
