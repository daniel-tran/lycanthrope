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
  
  void drawDoor(boolean hasUnlockedMaxDoors, PImage lockImg, color roomColour) {
    if (hasUnlockedMaxDoors) {
      fill(255, 0, 0);
    } else if (!isLocked) {
      fill(roomColour);
    } else {
      fill(0, 28, 128);
    }
    
    rectMode(CENTER);
    noStroke();
    // Use an offset for x,y coordinates only during drawing to allow it to be drawn
    // outside of the valid room space but still allow players to access them when unlocked.
    rect(x + offsetX, y + offsetY, doorWidth, doorHeight);
    
    if (!hasUnlockedMaxDoors) {
      imageMode(CENTER);
      image(lockImg, buttonX, buttonY, buttonWidth, buttonHeight);
    }
  }
}
