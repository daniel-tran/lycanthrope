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
  int xFlipScale = 1; // 1 = right, -1 = left
  PImage icon;
  int iconWidth = 48;
  int iconHeight = iconWidth;
  
  Player(int startX, int startY, int stepSizeX, int stepSizeY) {
    x = startX;
    y = startY;
    stepX = stepSizeX;
    stepY = stepSizeY;
    icon = loadImage("images/IconPlayer1.png");
  }
  
  void drawPlayer() {
    imageMode(CENTER);
    pushMatrix();
    scale(xFlipScale, 1);
    image(icon, x * xFlipScale, y, iconWidth, iconHeight);
    popMatrix();
  }
  
  // Sets the go-to coordinates
  void setDestination(int newX, int newY) {
    xFlipScale = (newX < x) ? -1 : 1;
    xGoTo = newX;
    yGoTo = newY;
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
  
  // Returns whether the player is within step distance to a given coordinate
  boolean isNearCoordinate(int coordinateX, int coordinateY) {
    return abs(coordinateY - y) < (iconHeight / 2) && abs(coordinateX - x) < (iconWidth / 2);
  }
  
  // Returns the direction of the room where the player can travel to another room.
  // This will modify the state of the player.
  // A return value of an empty string indicates that there is no room traversal occurring.
  String detectRoomTravel(HashMap<String, Door> roomDoors) {
    for (Map.Entry me: roomDoors.entrySet()) {
      Door door = roomDoors.get(me.getKey());
      if (isNearCoordinate(door.x, door.y) && !door.isLocked) {
        x = door.xWarpTo;
        y = door.yWarpTo;
        isMoving = false;
        return door.doorKey;
      }
    }
    return "";
  }
  
  int detectItems(ArrayList<Item> items) {
    for (int i = 0; i < items.size(); i++) {
      if (isNearCoordinate(items.get(i).x, items.get(i).y) && !items.get(i).isCollected) {
        items.get(i).setCollected();
        return items.get(i).id;
      }
    }
    return -1;
  }
}
