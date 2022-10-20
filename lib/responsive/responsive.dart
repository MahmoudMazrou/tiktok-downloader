int smalMobile = 240;
int mediumMobile = 300;
int largemMobile = 360;

int smalTablet = 480;
int midiumTablet = 600;
int midumlargTablet = 800;
int largTablet = 1280;

int getSliver(double size) {
  if (size >= smalMobile && size <= mediumMobile) {
    return 1;
  } else if (size > mediumMobile && size <= largemMobile) {
    return 2;
  } else if (size > largemMobile && size <= smalTablet) {
    return 2;
  } else if (size > smalTablet && size <= midiumTablet) {
    return 3;
  } else if (size > midiumTablet && size <= midumlargTablet) {
    return 4;
  } else if (size > midumlargTablet && size <= largTablet) {
    return 6;
  } else if (size > largTablet) {
    return 8;
  } else {
    return 8;
  }
}
