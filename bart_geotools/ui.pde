/**
 * Logic for drawing the legends and viz control components.
 *
 * (c) 2023 Regents of University of California / The Eric and Wendy Schmidt
 * Center for Data Science and the Environment at UC Berkeley. This file is
 * part of processing-geopoint released under the BSD 3-Clause License. See
 * LICENSE.md.
 *
 * @license BSD
 */

/**
 * Draw the UI layer.
 *
 * @param higlightedCodes Set of codes corresponding to stations highlighted by
 *    the user.
 */
void drawUi(Set<String> highlightedCodes) {
  drawTitle();
  drawToggleDisplay();
  
  for (LegendPanel panel : legendPanels) {
    panel.draw(highlightedCodes);
  }
  
  if (showingPopulation) {
    populationPanel.draw(highlightedCodes);
  }
}


/**
 * Build the legend UI components.
 *
 * @return Newly built legend panels.
 */
List<LegendPanel> buildLegendPanels() {
  List<LegendPanel> panels = new ArrayList<>();
  panels.add(new SelectedListPanel());
  panels.add(new HaloScalePanel());
  panels.add(new LineScalePanel());
  panels.add(new SymbolsPanel());
  return panels;
}


/**
 * Draw the visualization title.
 */
void drawTitle() {
  pushMatrix();
  pushStyle();
  
  noStroke();
  fill(UI_BG_COLOR_TITLE);
  rectMode(CORNER);
  rect(0, 0, 406, 24);
  
  noStroke();
  fill(#FFFFFF);
  textFont(TITLE_FONT);
  textAlign(CENTER, CENTER);
  text("SF Bay BART Daily Ridership Viz", 203, 12);
  
  popStyle();
  popMatrix();
}


/**
 * Draw controls for the population layer.
 *
 * Display if the population layer is currently being shown and show the user
 * how to toggle the layer by pressing a keyboard key.
 */
void drawToggleDisplay() {
  pushMatrix();
  pushStyle();
  
  noStroke();
  fill(UI_BG_COLOR_TITLE);
  rectMode(CORNER);
  rect(0, 26, 250, 14);
  
  noStroke();
  fill(#FFFFFF);
  textFont(BODY_FONT);
  textAlign(CENTER, CENTER);
  
  String message;
  if (showingPopulation) {
    message = "Press p to hide population.";
  } else {
    message = "Press p to overlay population.";
  }

  text(message, 125, 33);
  
  popStyle();
  popMatrix();
}


/**
 * Template method for drawing a UI panel.
 */
abstract class LegendPanel {
  
  /**
   * Get the x coordinate (pixel space) at which the panel should be draw.
   *
   * @return The x coordinate for the left side of the panel.
   */
  public abstract float getX();
  
  /**
   * Get how many pixels wide the panel should be.
   *
   * @return The panel width in pixels.
   */
  public abstract float getWidth();
  
  /**
   * Get the height of the panel in pixels.
   *
   * @return The vertical size of the panel.
   */
  public abstract float getPanelHeight();
  
  /**
   * Get the human-readable title to display in the panel title bar.
   *
   * @return Human-friendly description of the panel.
   */
  public abstract String getTitle();
  
  /**
   * Draw the contents of the panel.
   *
   * Draw the contents of the panel after having had translated to its upper
   * left hand corner. Note that the style and matrix will be pushed before
   * calling this and popped after calling it.
   *
   * @param higlightedCodes Set of codes corresponding to stations highlighted
   *    by the user.
   */
  public abstract void drawInner(Set<String> highlightedCodes);
  
  /**
   * Draw this panel.
   *
   * @param higlightedCodes Set of codes corresponding to stations highlighted
   *    by the user.
   */
  public void draw(Set<String> highlightedCodes) {
    pushMatrix();
    pushStyle();
    
    translate(getX(), height - getPanelHeight());
    noStroke();
    
    fill(UI_BG_COLOR_TITLE);
    rectMode(CORNER);
    rect(0, 0, getWidth(), 14);
    
    fill(#FFFFFF);
    textFont(BODY_FONT);
    textAlign(CENTER, CENTER);
    text(getTitle(), getWidth() / 2, 7);
    
    fill(UI_BG_COLOR_BODY);
    rectMode(CORNER);
    rect(0, 16, getWidth(), getPanelHeight() - 16 - 2);
    
    pushMatrix();
    pushStyle();
    
    translate(0, 16);
    drawInner(highlightedCodes);
    
    popStyle();
    popMatrix();
    
    popStyle();
    popMatrix();
  }
  
}


/**
 * Panel showing the names of the stations currently highlighted by the user.
 */
class SelectedListPanel extends LegendPanel {
  
  public float getX() {
    return 5;
  }
  
  public float getWidth() {
    return 150;
  }
  
  public float getPanelHeight() {
    return 150;
  }
  
  public String getTitle() {
    return "Selected Stations";
  }
  
  public void drawInner(Set<String> highlightedCodes) {
    fill(#FFFFFF);
    textFont(BODY_FONT);
    textAlign(LEFT, TOP);
    if (highlightedCodes.isEmpty()) {
      text("None", 2, 4);
    } else {
      String listStr = highlightedCodes.stream()
        .map((x) -> dataset.getStationByCode(x))
        .map((x) -> x.getName())
        .reduce((a, b) -> a + "\n" + b)
        .get();
      text(listStr, 2, 4, 146, 120);
    }
  }
  
}


/**
 * Panel describing station ridership in terms of halo radius.
 */
class HaloScalePanel extends LegendPanel {
  
  public float getX() {
    return 160;
  }
  
  public float getWidth() {
    return 132;
  }
  
  public float getPanelHeight() {
    return 170;
  }
  
  public String getTitle() {
    return "Area (# Riders)";
  }
  
  public void drawInner(Set<String> highlightedCodes) {
    noStroke();
    ellipseMode(RADIUS);
    textAlign(LEFT, CENTER);
    
    float y = 12;
    
    float step = maxStationCount / 5;
    
    for (float count = step; count <= maxStationCount; count += step) {
      float radius = getHaloRadius(count);
      
      fill(#A0A0A0);
      ellipse(20, y, radius, radius);
      
      fill(#FFFFFF);
      text(nfc(round(count), 0), 42, y);
      
      y += 5 + radius * 2;
    }
  }
  
}


/**
 * Panel describing the width of a line and its relation to ridership on a
 * journey between two stations.
 */
class LineScalePanel extends LegendPanel {
  
  public float getX() {
    return 297;
  }
  
  public float getWidth() {
    return 139;
  }
  
  public float getPanelHeight() {
    return 110;
  }
  
  public String getTitle() {
    return "Width (# Riders)";
  }
  
  public void drawInner(Set<String> highlightedCodes) {
    int y = 11;
    float step = maxEdgeCount / 5;
    
    fill(#FFFFFF);
    stroke(#a2a2a2);
    
    for (float count = step; count <= maxEdgeCount; count += step) {
      strokeWeight(getEdgeWidth(count));
      line(11, y, 51, y);
      
      textAlign(LEFT, CENTER);
      text(nfc(round(count), 0), 65, y);
      
      y += 17;
    }
  }

}


/**
 * Panel describing what a line, filled circle, and circle outline mean (journey,
 * selected station, and unselected station respectively).
 */
class SymbolsPanel extends LegendPanel {
  
  public float getX() {
    return 441;
  }
  
  public float getWidth() {
    return 120;
  }
  
  public float getPanelHeight() {
    return 70;
  }
  
  public String getTitle() {
    return "Legend";
  }
  
  public void drawInner(Set<String> highlightedCodes) {
    textAlign(LEFT, CENTER);
  
    fill(HALO_CENTER_COLOR_INACTIVE);
    stroke(HALO_BORDER);
    ellipse(7, 7, 3, 3);
    fill(#FFFFFF);
    text("Total Riders", 13, 7);
    
    fill(OVERLAP_COLOR);
    stroke(OVERLAP_COLOR);
    noStroke();
    ellipse(7, 21, 3, 3);
    fill(#FFFFFF);
    text("Highlighted", 13, 21);
    
    noFill();
    stroke(EDGE_COLOR_ACTIVE);
    strokeWeight(2);
    line(4, 35, 10, 35);
    noStroke();
    fill(#FFFFFF);
    text("Journey", 13, 35);
  }
  
}


/**
 * Panel describing the color scale used when drawing the population grid.
 */
class PopulationPanel extends LegendPanel {
  
  public float getX() {
    return 566;
  }
  
  public float getWidth() {
    return 94;
  }
  
  public float getPanelHeight() {
    return 140;
  }
  
  public String getTitle() {
    return "Population";
  }
  
  public void drawInner(Set<String> highlightedCodes) {
    textAlign(LEFT, CENTER);
    
    rectMode(RADIUS);
    
    float y = 12;
    float step = maxPopulation / 7;
    
    for (float count = step; count <= maxPopulation; count += step) {
      fill(#606060);
      rect(15, y, 5, 7);
      
      fill(getPopulationColor(count));
      rect(15, y, 5, 7);
      
      fill(#FFFFFF);
      text(nfc(round(count), 0), 27, y);
      
      y += 16;
      
    }
  }
  
}
