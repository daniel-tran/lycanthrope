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
  
  Door(String _doorKey, int buttonLength, int startX, int startY, int warpToX, int warpToY) {
    doorKey = _doorKey;
    buttonWidth = buttonLength;
    buttonHeight = buttonWidth;
    x = startX;
    y = startY;
    xWarpTo = warpToX;
    yWarpTo = warpToY;
    
    buttonX = x;
    buttonY = y;
    int buttonOffsetX = int(buttonWidth * 0.9);
    int buttonOffsetY = int(buttonHeight * 0.9);
    switch(doorKey) {
      case "N":
        buttonY -= buttonOffsetY;
        break;
      case "E":
        buttonX += buttonOffsetX;
        break;
      case "W":
        buttonX -= buttonOffsetX;
        break;
      case "S":
        buttonY += buttonOffsetY;
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
  
  void drawDoor(boolean hasUnlockedMaxDoors) {    
    if (hasUnlockedMaxDoors) {
      fill(255, 0, 0);
    } else if (!isLocked) {
      fill(0, 28, 128);
    } else {
      fill(0, 255, 0);
    }
    
    rectMode(CENTER);
    noStroke();
    if (doorKey == "N" || doorKey == "S") {
      rect(x, y, 50, 25);
    } else {
      rect(x, y, 25, 50);
    }
    
    if (!hasUnlockedMaxDoors) {
      ellipseMode(CENTER);
      stroke(0);
      if (!isLocked) {
        fill(255, 0, 0);
      } else {
        fill(0, 255, 0);
      }
      ellipse(buttonX, buttonY, buttonWidth, buttonHeight);
    }
  }
}
