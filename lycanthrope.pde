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

Player PLAYER;
ArrayList<Room> ROOMS = new ArrayList<Room>();
int ROOM_CURRENT_INDEX;
ArrayList<Item> ITEMS_COLLECTED = new ArrayList<Item>();
Stats GAME_STATS = new Stats();

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
  ROOMS.add(new Room(6, 1, 3, 2));
  ROOMS.add(new Room(7, 2, 4, 0));
  ROOMS.add(new Room(8, 0, 5, 1));
  
  ROOMS.add(new Room(0, 4, 6, 5));
  ROOMS.add(new Room(1, 5, 7, 3));
  ROOMS.add(new Room(2, 3, 8, 4));
  
  ROOMS.add(new Room(3, 7, 0, 8));
  ROOMS.add(new Room(4, 8, 1, 6));
  ROOMS.add(new Room(5, 6, 2, 7));
  
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
  
  for (int i = ITEM_STAGE_COMPLETE; i < ITEMS_COUNT; i++) {
    int roomIndex = int(random(ROOMS.size()));
    println("Item is in room " + roomIndex);
    ROOMS.get(roomIndex).addItem(i, X_MIN, X_MAX, Y_MIN, Y_MAX);
  }
}

void setup() {
  size(960, 540);
  X_MAX = width - X_MIN;
  Y_MAX = height - Y_MIN;
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

void mainGameLoop() {
  background(#C7A07A);
  if (PLAYER.isMoving) {
    PLAYER.doTravel();
  }
  String warpKey = PLAYER.detectRoomTravel(ROOMS.get(ROOM_CURRENT_INDEX).doors);
  if (warpKey.length() > 0) {
    ROOM_CURRENT_INDEX = ROOMS.get(ROOM_CURRENT_INDEX).warpMap.get(warpKey);
    GAME_STATS.registerRoomTraverse();
  } else {
    int collectedItemId = PLAYER.detectItems(ROOMS.get(ROOM_CURRENT_INDEX).items);
    if (collectedItemId >= 0) {
      // Items are positioned as part of the final display once the stage is complete
      ITEMS_COLLECTED.add(new Item(collectedItemId, X_MIN + (X_MIN * ITEMS_COLLECTED.size()), int(height * 0.75)));
      if (collectedItemId == ITEM_STAGE_COMPLETE) {
        // Stage completes after collecting the necessary item
        GAME_STATE = GameState.STAGE_COMPLETE;
      }
    }
  }
  
  noStroke();
  rectMode(CORNERS);
  fill(0, 28, 128);
  rect(X_MIN, Y_MIN, X_MAX, Y_MAX);
  
  ROOMS.get(ROOM_CURRENT_INDEX).drawRoom();
  
  stroke(0);
  fill(255);
  circle(PLAYER.x, PLAYER.y, 10);
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
