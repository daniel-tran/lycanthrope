class Item {
  int id;
  int x;
  int y;
  String name;
  // Items are OK to store image data since most items will use dedicated sprites
  // though it's worth keeping an eye on this if duplicate items are supported.
  PImage sprite;
  int spriteWidth = 36;
  int spriteHeight = spriteWidth;
  boolean isCollected = false;
  
  Item(int itemId, int startX, int startY) {
    setPropertiesFromItemId(itemId);
    x = startX;
    y = startY;
  }
  
  // Sets various class members based on its ID (including the id property itself)
  void setPropertiesFromItemId(int itemId) {
    id = itemId;
    sprite = loadImage("images/Item" + itemId +".png");
    switch(itemId) {
      case 0:
        name = "Cure";
        break;
      case 1:
        name = "Fish";
        break;
      case 2:
        name = "Homsar's Hat";
        break;
      case 3:
        name = "Bear Plush";
        break;
      case 4:
        name = "Bread";
        break;
    }
  }
  
  void drawItem() {
    if (!isCollected) {
      imageMode(CENTER);
      image(sprite, x, y, spriteWidth, spriteHeight);
    }
  }
  
  void setCollected() {
    println("You found a " + name);
    isCollected = true;
  }
}
