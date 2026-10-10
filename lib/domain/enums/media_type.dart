enum MediaType {
  image('Image'),
  video('Video'),
  carousel('Carousel'),
  textOnly('Text Only');

  const MediaType(this.label);
  final String label;

  bool get hasMedia => this != MediaType.textOnly;
}
