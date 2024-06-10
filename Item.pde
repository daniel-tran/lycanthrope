class Item {
  int id;
  int x;
  int y;
  String name;
  color colour;
  boolean isCollected = false;
  
  Item(int itemId, int startX, int startY) {
    setPropertiesFromItemId(itemId);
    x = startX;
    y = startY;
  }
  
  // Sets various class members based on its ID (including the id property itself)
  void setPropertiesFromItemId(int itemId) {
    id = itemId;
    switch(itemId) {
      case 0:
        name = "Cure";
        colour = #BCDDB3;
        break;
      case 1:
        name = "Fish";
        colour = #E9967A;
        break;
      case 2:
        name = "Homsar's Hat";
        colour = #E7B53B;
        break;
      case 3:
        name = "Bear Plush";
        colour = #694D3A;
        break;
      case 4:
        name = "Bread";
        colour = #C5AF91;
        break;
    }
  }
  
  void drawItem() {
    if (!isCollected) {
      rectMode(CENTER);
      fill(colour);
      rect(x, y, 16, 16);
    }
  }
  
  void setCollected() {
    println("You found a " + name);
    isCollected = true;
  }
}
