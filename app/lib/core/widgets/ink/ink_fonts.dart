/// 「墨落」全 App 字体族。
///
/// - [kSerif]：标题、题字、价值语（衬线，宋/明体气质）。
/// - [kMono]：参数、时间戳、技术小字（等宽，只作"落款"式点缀）。
///
/// ⚠ Android 上以系统族名兜底，CJK 可能回退到系统无衬线（首页同款取舍）。
/// TODO(字体)：正式版打包 `Noto Serif SC`（600/900）子集 + `Ma Shan Zheng`（只留「记」），
/// 见 v11 的「工程侧 TODO · 字体子集化」。
const String kSerif = 'serif';
const String kMono = 'monospace';
