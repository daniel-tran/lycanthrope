class Door {
  int x;
  int y;
  int xWarpTo;
  int yWarpTo;
  boolean isLocked = true;
  String doorKey;
  int buttonX;
  int buttonY;
  int buttonWidth;
  int buttonHeight;
  int doorWidth;
  int doorHeight;
  int offsetX = 0;
  int offsetY = 0;
  
  Door(String _doorKey, int dWidth, int dHeight, int buttonLength, int startX, int startY, int warpToX, int warpToY) {
    doorKey = _doorKey;
    doorWidth = dWidth;
    doorHeight = dHeight;
    buttonWidth = buttonLength;
    buttonHeight = buttonWidth;
    x = startX;
    y = startY;
    xWarpTo = warpToX;
    yWarpTo = warpToY;
    
    buttonX = x;
    buttonY = y;
    int buttonOffsetX = buttonWidth;
    int buttonOffsetY = buttonHeight;
    switch(doorKey) {
      case "N":
        buttonY -= buttonOffsetY;
        offsetY = int(doorHeight / 2) * -1;
        break;
      case "E":
        buttonX += buttonOffsetX;
        offsetX = int(doorWidth / 2);
        break;
      case "W":
        buttonX -= buttonOffsetX;
        offsetX = int(doorWidth / 2) * -1;
        break;
      case "S":
        buttonY += buttonOffsetY;
        offsetY = int(doorHeight / 2);
        break;
    }
  }
  
  // Toggles the locked status
  void toggleLocked() {
    isLocked = !isLocked;
  }
  
  // Returns whether the door's button is pressed at a given coordinate
  boolean isPressed(int coordinateX, int coordinateY) {
    return abs(coordinateY - buttonY) < (buttonHeight / 2) && abs(coordinateX - buttonX) < (buttonWidth / 2);
  }
  
  // Draws a metal square with some basic shading
  void drawLockedSquare(int x, int y, color brightest, color surface, color darkest) {
    float doorWidthFactor = 0.8;
    float doorHeightFactor = 0.8;
    float doorWidthRadius = doorWidth / 2;
    float doorHeightRadius = doorHeight / 2;
    
    // Draw the brightest and darkest parts first, since they will have other items drawn on top
    stroke(darkest);
    fill(darkest);
    triangle(x + doorWidthRadius, y - doorHeightRadius, x + doorWidthRadius, y + doorHeightRadius, x - doorWidthRadius, y + doorHeightRadius);
    fill(brightest);
    triangle(x - doorWidthRadius, y - doorHeightRadius, x + doorWidthRadius, y - doorHeightRadius, x - doorWidthRadius, y + doorHeightRadius);
    
    // Draw line to divide the second diagonal of the square (first diagonal is essentially drawn for free)
    line(x - doorWidthRadius, y - doorHeightRadius, x + doorWidthRadius, y + doorHeightRadius);
    
    // Draw the surface face
    rectMode(CENTER);
    fill(surface);
    rect(x, y, doorWidth * doorWidthFactor, doorHeight * doorHeightFactor);
  }
  
  void drawDoor(boolean hasUnlockedMaxDoors, PImage lockImg, color roomColour) {
    // Use an offset for x,y coordinates only during drawing to allow it to be drawn
    // outside of the valid room space but still allow players to access them when unlocked.
    int xWithOffset = x + offsetX;
    int yWithOffset = y + offsetY;
    
    if (hasUnlockedMaxDoors) {
      drawLockedSquare(xWithOffset, yWithOffset, #DE9294, #B8383B, #803020);
    } else if (!isLocked) {
      fill(roomColour);
      rectMode(CENTER);
      noStroke();
      rect(xWithOffset, yWithOffset, doorWidth, doorHeight);
    } else {
      drawLockedSquare(xWithOffset, yWithOffset, #FFFFFF, #C3C3C3, #7F7F7F);
    }
    
    if (!hasUnlockedMaxDoors) {
      float centreOffsetX = offsetX * 0.25;
      float centreOffsetY = offsetY * 0.25;
      imageMode(CENTER);
      image(lockImg, buttonX - centreOffsetX, buttonY - centreOffsetY, buttonWidth, buttonHeight);
    }
  }
}
