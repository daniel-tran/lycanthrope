class Item {
  int x;
  int y;
  String name;
  boolean isCollected = false;
  
  Item(String itemName, int startX, int startY) {
    name = itemName;
    x = startX;
    y = startY;
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
