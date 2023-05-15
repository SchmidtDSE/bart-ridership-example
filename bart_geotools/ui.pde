void drawUi(Set<String> highlightedCodes) {
  drawTitle();
  
  for (LegendPanel panel : legendPanels) {
    panel.draw(highlightedCodes);
  }
}


List<LegendPanel> buildLegendPanels() {
  List<LegendPanel> panels = new ArrayList<>();
  panels.add(new SelectedListPanel());
  panels.add(new HaloScalePanel());
  panels.add(new LineScalePanel());
  panels.add(new SymbolsPanel());
  return panels;
}


void drawTitle() {
  pushMatrix();
  pushStyle();
  
  noStroke();
  fill(UI_BG_COLOR_TITLE);
  rectMode(CORNER);
  rect(0, 0, 250, 24);
  
  noStroke();
  fill(#FFFFFF);
  textFont(TITLE_FONT);
  textAlign(CENTER, CENTER);
  text("BART Ridership Viz", 125, 12);
  
  popStyle();
  popMatrix();
}


abstract class LegendPanel {
  
  public abstract float getX();
  
  public abstract float getWidth();
  
  public abstract float getPanelHeight();
  
  public abstract String getTitle();
  
  public abstract void drawInner(Set<String> highlightedCodes);
  
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


class SelectedListPanel extends LegendPanel {
  
  public float getX() {
    return 5;
  }
  
  public float getWidth() {
    return 250;
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
      text(listStr, 2, 4, 246, 120);
    }
  }
  
}


class HaloScalePanel extends LegendPanel {
  
  public float getX() {
    return 260;
  }
  
  public float getWidth() {
    return 150;
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


class LineScalePanel extends LegendPanel {
  
  public float getX() {
    return 415;
  }
  
  public float getWidth() {
    return 150;
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
    
    for (float count = step; count <= maxEdgeCount; count += step) {
      fill(#FFFFFF);
      stroke(#a2a2a2);
      strokeWeight(getEdgeWidth(count));
      
      fill(#FFFFFF);
      line(11, y, 51, y);
      
      textAlign(LEFT, CENTER);
      text(nfc(round(count), 0), 65, y);
      
      y += 17;
    }    sx
    
  }
  
}


class SymbolsPanel extends LegendPanel {
  
  public float getX() {
    return 570;
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
    text("Journies", 13, 35);
  }
  
}
