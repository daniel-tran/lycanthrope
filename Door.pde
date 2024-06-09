class Door {
  int x;
  int y;
  int xWarpTo;
  int yWarpTo;
  boolean isLocked = true;
  String doorKey;
  
  Door(String _doorKey, int startX, int startY, int warpToX, int warpToY) {
    doorKey = _doorKey;
    x = startX;
    y = startY;
    xWarpTo = warpToX;
    yWarpTo = warpToY;
  }
  
  // Toggles the locked status
  void toggleLocked() {
    isLocked = !isLocked;
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
    if (doorKey == "N" || doorKey == "S") {
      rect(x, y, 50, 25);
    } else {
      rect(x, y, 25, 50);
    }
  }
}
