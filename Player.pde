class Player {
  int x;
  int y;
  int stepX;
  int stepY;
  boolean isMoving = false;
  int xGoTo;
  int yGoTo;
  int xMin;
  int yMin;
  int xMax;
  int yMax;
  
  Player(int startX, int startY, int stepSizeX, int stepSizeY) {
    x = startX;
    y = startY;
    stepX = stepSizeX;
    stepY = stepSizeY;
  }
  
  // Sets the go-to coordinates
  void setDestination(int x, int y) {
    xGoTo = x;
    yGoTo = y;
    isMoving = true;
  }
  
  // Moves the user to the known go-to coordinates.
  // If the player is at these coordinates, the player's moving status is reset.
  void doTravel() {
    if (x != xGoTo) {
      if (xGoTo > x) {
        x += stepX;
      } else {
        x -= stepX;
      }
      
      if (abs(xGoTo - x) < stepX) {
        x = xGoTo;
      }
    } else if (y != yGoTo) {
      if (yGoTo > y) {
        y += stepY;
      } else {
        y -= stepY;
      }
      
      if (abs(yGoTo - y) < stepY) {
        y = yGoTo;
      }
    } else {
      isMoving = false;
    }
  }
  
  // Sets the bounds for where a player can move
  void setTravelBoundaries(int minX, int maxX, int minY, int maxY) {
    xMin = minX;
    xMax = maxX;
    yMin = minY;
    yMax = maxY;
  }
  
  // Returns the direction of the room where the player can travel to another room.
  // This will modify the state of the player.
  // A return value of an empty string indicates that there is no room traversal occurring.
  String detectRoomTravel(HashMap<String, Door> roomDoors) {
    for (Map.Entry me: roomDoors.entrySet()) {
      Door door = roomDoors.get(me.getKey());
      if (abs(door.y - y) < stepY && abs(door.x - x) < stepY && !door.isLocked) {
        x = door.xWarpTo;
        y = door.yWarpTo;
        isMoving = false;
        return door.doorKey;
      }
    }
    return "";
  }
}
