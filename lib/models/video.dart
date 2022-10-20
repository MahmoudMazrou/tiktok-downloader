class VideoModel {
  String id;
  String url;
  String? downloadAddr;
  String thumbUrl;
  String watchesCount;
  VideoModel({required this.id,required this.url,required this.thumbUrl,required this.watchesCount,required this.downloadAddr});
}