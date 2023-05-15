final float MAP_CENTER_LONGITUDE = -122.4;
final float MAP_CENTER_LATITUDE = 37.85;
final float MAP_CENTER_X = 250;
final float MAP_CENTER_Y = 250;
final float MAP_SCALE = 85;

final float MIN_HALO_RADIUS = 0;
final float MAX_HALO_RADIUS = 300;
final float MIN_EDGE_WIDTH = 0;
final float MAX_EDGE_WIDTH = 15;

final color UI_BG_COLOR_TITLE = #F0333333;
final color UI_BG_COLOR_BODY = #A0333333;

final color HALO_CENTER_COLOR_INACTIVE = #30FFFFFF;
final color HALO_CENTER_COLOR_ACTIVE = #FFFFFF;
final color HALO_BORDER = #FFFFFF;
final color OVERLAP_COLOR = #FFFFFF;
final color EDGE_COLOR_ACTIVE = #50FFFFFF;
final color EDGE_COLOR_INACTIVE = #10FFFFFF;

final color[] POPULATION_COLORS = {
  #4008519c,
  #403182bd,
  #406baed6,
  #409ecae1,
  #40c6dbef,
  #40eff3ff,
  #40ffffff
};

PFont BODY_FONT;
PFont TITLE_FONT;

void loadAssets() {
  BODY_FONT = loadFont("Silkscreen-Regular-12.vlw");
  TITLE_FONT = loadFont("Silkscreen-Regular-20.vlw");
}
