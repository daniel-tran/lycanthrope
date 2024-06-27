class Item {
  int id;
  int idMax = 31;
  int x;
  int y;
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
    // Only spawn the cure item once, all others wrap around and are repeated
    int imageId = itemId == 0 ? 0 : itemId % idMax + 1;
    sprite = loadImage("images/Item" + imageId +".png");
  }
  
  void drawItem() {
    if (!isCollected) {
      imageMode(CENTER);
      image(sprite, x, y, spriteWidth, spriteHeight);
    }
  }
  
  void setCollected() {
    isCollected = true;
  }
}
