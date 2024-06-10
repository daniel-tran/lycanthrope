class Item {
  int id;
  int x;
  int y;
  String name;
  boolean isCollected = false;
  
  Item(int itemId, int startX, int startY) {
    id = itemId;
    name = getNameFromItemId(itemId);
    x = startX;
    y = startY;
  }
  
  // Returns the item's name based on its ID
  String getNameFromItemId(int itemId) {
    switch(itemId) {
      case 1: return "Cure";
    }
    return "";
  }
  
  void drawItem() {
    if (!isCollected) {
      rectMode(CENTER);
      fill(188, 221, 179);
      rect(x, y, 16, 16);
    }
  }
  
  void setCollected() {
    println("You found a " + name);
    isCollected = true;
  }
}
