import java.util.Map;

int X_MIN = 50;
int X_MAX = X_MIN;
int Y_MIN = 50;
int Y_MAX = Y_MIN;
int DOORS_BUTTON_LENGTH = 30;
enum GameState {
  IN_GAME,
  STAGE_COMPLETE
};
GameState GAME_STATE = GameState.IN_GAME;
int ITEM_STAGE_COMPLETE = 0;
int ITEMS_COUNT = 5;
int STAGE_COMPLETE_ITEMS_X = 450;
int STAGE_COMPLETE_ITEMS_Y = 150;
int STAGE_COMPLETE_ITEMS_ROW = 9;

Player PLAYER;
ArrayList<Room> ROOMS = new ArrayList<Room>();
int ROOM_CURRENT_INDEX;
ArrayList<Item> ITEMS_COLLECTED = new ArrayList<Item>();
Stats GAME_STATS = new Stats();
HashMap<String, PImage> GAME_IMAGES = new HashMap<String, PImage>();

// Returns the direction corresponding to the opposite of the given value
String getOppositeDirection(String direction) {
  switch(direction) {
    case "N": return "S";
    case "E": return "W";
    case "W": return "E";
    case "S": return "N";
  }
  return "";
}

// Swaps the room indexes for 2 specified rooms in a given direction per room.
// This will also implicitly swap the room indexes for whatever rooms are currently being connected by these rooms in the specified directions.
// For visual clarity, suppose this is a sample of the current warp mapping of some rooms:
// Room 4 -- Door E --> Room 5
// Room 2 <-- Door W -- Room 0
//
// If we invoke swapWarps(4, 0, "E", "W"), the following warp mappings are modified:
// Room 4 -- Door E --> Room 0
// Room 4 <-- Door W -- Room 0
// Room 2 -- Door E --> Room 5
// Room 2 <-- Door W -- Room 5
void swapWarps(int roomIndexFrom, int roomIndexTo, String directionFrom, String directionTo) {
  int roomFromCurrentWarp = ROOMS.get(roomIndexFrom).warpMap.get(directionFrom);
  String roomFromCurrentWarpDirection = getOppositeDirection(directionFrom);
  
  int roomToCurrentWarp = ROOMS.get(roomIndexTo).warpMap.get(directionTo);
  String roomToCurrentWarpDirection = getOppositeDirection(directionTo);
  
  println("Swapping rooms " + roomIndexFrom + " <--> " + roomIndexTo + " (" + directionFrom + ", " + directionTo + ")");
  ROOMS.get(roomIndexFrom).warpMap.put(directionFrom, roomIndexTo);
  ROOMS.get(roomIndexTo).warpMap.put(directionTo, roomIndexFrom);
  
  println("Swapping rooms " + roomFromCurrentWarp + " <--> " + roomToCurrentWarp + " (" + roomFromCurrentWarpDirection + ", " + roomToCurrentWarpDirection + ")");
  ROOMS.get(roomFromCurrentWarp).warpMap.put(roomFromCurrentWarpDirection, roomToCurrentWarp);
  ROOMS.get(roomToCurrentWarp).warpMap.put(roomToCurrentWarpDirection, roomFromCurrentWarp);
}

void toggleRoom(String keyCap) {
  println("Setting room status for " + ROOM_CURRENT_INDEX + " & " + ROOMS.get(ROOM_CURRENT_INDEX).warpMap.get(keyCap));
  
  if (ROOMS.get(ROOM_CURRENT_INDEX).canToggleDoor(keyCap)) {
    // Lock/Unlock the door from both sides
    println("Toggling doors for " + keyCap + " & " + getOppositeDirection(keyCap));
    ROOMS.get(ROOM_CURRENT_INDEX).doors.get(keyCap).toggleLocked();
    ROOMS.get(ROOMS.get(ROOM_CURRENT_INDEX).warpMap.get(keyCap)).doors.get(getOppositeDirection(keyCap)).toggleLocked();
  }
}

// Restarts the state of various global variables.
// For ArrayList variables, calling the clear() function should be good enough and hopefully more performant that reinitialisation
void gameReset() {
  PLAYER = new Player(width / 2, height / 2, 5, 5);
  PLAYER.setTravelBoundaries(X_MIN, X_MAX, Y_MIN, Y_MAX);
  ITEMS_COLLECTED.clear();
  ROOMS.clear();
  
  // Generate a new set of rooms, conceptualised into a grid.
  int roomWidth = 3;
  int roomHeight = roomWidth;
  int totalRooms = roomWidth * roomHeight;
  for (int col = 0; col < roomWidth; col++) {
    for (int row = 0; row < roomHeight; row++) {
      int rowCurrent = row * roomWidth;
      int roomCurrent = rowCurrent + col;
      // Up and down are determined by taking the current room and adding or subtracting
      // an entre row's worth of rooms. The value also needs to be added to totalRooms
      // and then to reduce modulo totalRooms to ensure the value rolls around correctly
      // if the room is on the top or bottom of the grid.
      int up = (totalRooms + (roomCurrent - roomWidth)) % totalRooms;
      int down = (totalRooms + (roomCurrent + roomWidth)) % totalRooms;
      // Left and right are determined by taking the current row and adding a factor of
      // the row as some calculation of the column index +/- 1. The value also needs to be
      // added to roomWidth and then to reduce modulo roomWidth to ensure the value rolls
      // around correctly if the room if on the leftmost or rightmost side of the grid.
      int left = rowCurrent + ((roomWidth + (col - 1)) % roomWidth);
      int right = rowCurrent + ((roomWidth + (col + 1)) % roomWidth);
      println("Room " + roomCurrent + ", Up: " + up + ", Right: " + right + ", Down: " + down + ", Left: " + left);
      
      ROOMS.add(new Room(up, right, down, left));
    }
  }

  ROOM_CURRENT_INDEX = int(random(ROOMS.size()));
  for (int r = 0; r < ROOMS.size(); r++) {
    ROOMS.get(r).setDoors(X_MIN, X_MAX, Y_MIN, Y_MAX, DOORS_BUTTON_LENGTH);
    // Since doors and warp locations are stored as different Room class members,
    // it's possible to randomise the warp maps during the set up of the doors.
    for (Map.Entry me: ROOMS.get(r).doors.entrySet()) {
      String direction = ROOMS.get(r).doors.get(me.getKey()).doorKey;
      int roomToSwap = int(random(ROOMS.size()));
      // Room cannot warp to itself, so just go to the next room instead.
      // This assumes the number of rooms available is >1.
      if (roomToSwap == r) {
        roomToSwap = (roomToSwap + 1) % ROOMS.size();
      }
      swapWarps(r, roomToSwap, direction, getOppositeDirection(direction));
    }
  }
  
  // Randomise items among each room, excluding the stage completion item
  for (int i = ITEM_STAGE_COMPLETE + 1; i < ITEMS_COUNT; i++) {
    int roomIndex = int(random(ROOMS.size()));
    println("Item is in room " + roomIndex);
    ROOMS.get(roomIndex).addItem(i, X_MIN, X_MAX, Y_MIN, Y_MAX);
  }
  
  // Due to the way rooms are currently randomised, it's possible for rooms to connect in such
  // a way that some rooms cannot be accessed. As such, the stage completion item is determined
  // through a simulated play of the maze and placed in whatever the last room reached was.
  // This should (hopefully) guarantee that each generated maze iscan be solved.
  int itemStageCompleteIndex = ROOM_CURRENT_INDEX;
  String[] directions = new String[]{ "N", "E", "S", "W" };
  for (int r = 0; r < ROOMS.size(); r++) {
    int doorIndex = int(random(directions.length));
    itemStageCompleteIndex = ROOMS.get(itemStageCompleteIndex).warpMap.get(directions[doorIndex]);
  }
  ROOMS.get(itemStageCompleteIndex).addItem(ITEM_STAGE_COMPLETE, X_MIN, X_MAX, Y_MIN, Y_MAX);
  println("Cure is in room " + itemStageCompleteIndex);
}

void setup() {
  size(960, 540);
  X_MAX = width - X_MIN;
  Y_MAX = height - Y_MIN;
  GAME_IMAGES.put("LOCK_DISABLED", loadImage("images/LockDisabled.png"));
  GAME_IMAGES.put("LOCK_ENABLED", loadImage("images/LockEnabled.png"));
  gameReset();
}

void mousePressed() {
  switch(GAME_STATE) {
    case IN_GAME:
      println(mouseX + ", " + mouseY);
      // Keep the player within a certain border of the room
      if (mouseX > X_MIN && mouseX < X_MAX && mouseY > Y_MIN && mouseY < Y_MAX) {
        PLAYER.setDestination(mouseX, mouseY);
      } else {
        for (Map.Entry me: ROOMS.get(ROOM_CURRENT_INDEX).doors.entrySet()) {
          if (ROOMS.get(ROOM_CURRENT_INDEX).doors.get(me.getKey()).isPressed(mouseX, mouseY)) {
            toggleRoom(ROOMS.get(ROOM_CURRENT_INDEX).doors.get(me.getKey()).doorKey);
            
            if (ROOMS.get(ROOM_CURRENT_INDEX).doors.get(me.getKey()).isLocked) {
              GAME_STATS.registerDoorLock();
            } else {
              GAME_STATS.registerDoorUnlock();
            }
          }
        }
      }
      println("You are in room " + ROOM_CURRENT_INDEX);
      break;
    case STAGE_COMPLETE:
      GAME_STATE = GameState.IN_GAME;
      GAME_STATS.increaseStageAndReset();
      gameReset();
      break;
  }
}

// Draws a simple brick pattern
void drawBackground() {
  background(#C7A07A);
  stroke(#000000);
  
  int brickHeight = 5;
  int brickWidth = 10;
  for (int y = 0; y < height; y += brickHeight) {
    boolean isEvenRow = y % 2 == 0;
    line(0, y, width, y);
    
    int x = isEvenRow ? int(brickWidth * 0.5) : 0;
    for (; x < width; x += brickWidth) {
      line(x, y, x, y + brickHeight);
    }
  }
}

void mainGameLoop() {
  // In reality, the walls encompass everything but objects are drawn on top to
  // make it look like a bordered room.
  drawBackground();
  if (PLAYER.isMoving) {
    PLAYER.doTravel();
  }
  Room currentRoom = ROOMS.get(ROOM_CURRENT_INDEX);
  String warpKey = PLAYER.detectRoomTravel(currentRoom.doors);
  if (warpKey.length() > 0) {
    ROOM_CURRENT_INDEX = currentRoom.warpMap.get(warpKey);
    GAME_STATS.registerRoomTraverse();
  } else {
    int collectedItemId = PLAYER.detectItems(currentRoom.items);
    if (collectedItemId >= 0) {
      // Items are positioned as part of the final display once the stage is complete
      // They are shown from left to right and shift to the next row once the row is full
      int itemX = STAGE_COMPLETE_ITEMS_X + (X_MIN * (ITEMS_COLLECTED.size() % STAGE_COMPLETE_ITEMS_ROW ));
      int itemY = STAGE_COMPLETE_ITEMS_Y + (Y_MIN * (ITEMS_COLLECTED.size() / STAGE_COMPLETE_ITEMS_ROW ));
      ITEMS_COLLECTED.add(new Item(collectedItemId, itemX, itemY));
      if (collectedItemId == ITEM_STAGE_COMPLETE) {
        // Stage completes after collecting the necessary item
        GAME_STATE = GameState.STAGE_COMPLETE;
      }
    }
  }
  
  // Draw the area in which the player can move
  noStroke();
  rectMode(CORNERS);
  fill(currentRoom.roomColour);
  rect(X_MIN, Y_MIN, X_MAX, Y_MAX);
  // Pass images into the draw functions to avoid storing them multiple times for each Door class instance
  currentRoom.drawRoom(GAME_IMAGES.get("LOCK_ENABLED"), GAME_IMAGES.get("LOCK_DISABLED"));

  PLAYER.drawPlayer();
}

void stageCompleteLoop() {
  background(128, 128, 0);
  fill(255, 255, 255);
  textSize(64);
  textAlign(CENTER);
  text("Stage "+ GAME_STATS.stage + " complete!", width / 2, Y_MIN);
  
  textSize(32);
  textAlign(LEFT);
  ArrayList<String> statsList = GAME_STATS.getStatsList();
  int statsY = int(height * 0.25);
  int statsYInc = Y_MIN;
  for (int s = 0; s < statsList.size(); s++) {
    text(statsList.get(s), X_MIN, statsY + (statsYInc * s));
  }
  
  for (int i = 0; i < ITEMS_COLLECTED.size(); i++) {
    ITEMS_COLLECTED.get(i).drawItem();
  }
  
  fill(255, 255, 255);
  textSize(32);
  textAlign(CENTER);
  text("Press the screen for the next stage", width / 2, Y_MAX);
}

void draw() {
  switch(GAME_STATE) {
    case IN_GAME:
      mainGameLoop();
      break;
    case STAGE_COMPLETE:
      stageCompleteLoop();
      break;
  }
}
