class Room {
  HashMap<String, Integer> warpMap = new HashMap<String, Integer>();  
  HashMap<String, Door> doors = new HashMap<String, Door>();
  ArrayList<Item> items = new ArrayList<Item>();
  int unlockedDoorsMax = 2;
  color roomColour;
  
  Room(int roomIndexN, int roomIndexE, int roomIndexS, int roomIndexW) {
    warpMap.put("N", roomIndexN);
    warpMap.put("E", roomIndexE);
    warpMap.put("S", roomIndexS);
    warpMap.put("W", roomIndexW);
    int[] rgb = new int[3];
    for (int i = 0; i < rgb.length; i++) {
      rgb[i] = int(random(256));
    }
    roomColour = color(rgb[0], rgb[1], rgb[2]);
  }
  
  // Handles set up of doors in the room
  void setDoors(int xMin, int xMax, int yMin, int yMax, int buttonLength) {
    doors.clear();
    doors.put("N", new Door("N", xMin, yMin, buttonLength, width / 2, yMin, width / 2, yMax - yMin));
    doors.put("S", new Door("S", xMin, yMin, buttonLength, width / 2, yMax, width / 2, yMin * 2));
    doors.put("W", new Door("W", xMin, yMin, buttonLength, xMin, height / 2, xMax - xMin, height / 2));
    doors.put("E", new Door("E", xMin, yMin, buttonLength, xMax, height / 2, xMin * 2, height / 2));
  }
  
  // Returns a list of directions matching the given parameters
  ArrayList<String> getDoors(boolean isLocked) {
    ArrayList<String> result = new ArrayList<String>();
    for (Map.Entry me: doors.entrySet()) {
      if (doors.get(me.getKey()).isLocked == isLocked) {
        result.add(me.getKey().toString());
      }
    }
    return result;
  }
  
  // Returns if a door can be interacted with. This does not modify the door state.
  // An interaction means the door can move from unlocked --> locked or vice versa.
  boolean canToggleDoor(String direction) {
    if (!doors.get(direction).isLocked) {
      // Doors can always be locked
      return true;
    }
    
    ArrayList<String> unlockedDoors = getDoors(false);
    if (unlockedDoors.size() >= unlockedDoorsMax) {
      // Too many open doors
      return false;
    }
    
    // Door can be opened since the threshold hasn't been reached
    return true;
  }
  
  void drawRoom(PImage lockDisabledImg, PImage lockEnabledImg) {
    ArrayList<String> unlockedDoors = getDoors(false);
    for (Map.Entry me: doors.entrySet()) {
      boolean isPermaLocked = !unlockedDoors.contains(me.getKey()) && unlockedDoors.size() >= unlockedDoorsMax;
      // Select the right icon for the door when it can be interacted with
      PImage lockImg = doors.get(me.getKey()).isLocked ? lockEnabledImg : lockDisabledImg;
      doors.get(me.getKey()).drawDoor(isPermaLocked, lockImg, roomColour);
    }
    for (int i = 0; i < items.size(); i++) {
      items.get(i).drawItem();
    }
  }
  
  void addItem(int itemId, int xMin, int xMax, int yMin, int yMax) {
    int itemX = xMin + int(random(xMax - xMin));
    int itemY = yMin + int(random(yMax - yMin));
    items.add(new Item(itemId, itemX, itemY));
  }
}
