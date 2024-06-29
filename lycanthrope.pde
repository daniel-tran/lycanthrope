import java.util.Map;
import processing.sound.*;

int UNIT_X;
int UNIT_Y;
int X_MIN = 50;
int X_MAX = X_MIN;
int Y_MIN = 50;
int Y_MAX = Y_MIN;
int Y_STAGE_COMPLETE;
int DOORS_BUTTON_LENGTH = 30;
enum GameState {
  INTRO,
  IN_GAME,
  STAGE_COMPLETE,
  GAME_WIN,
  GAME_LOSE,
};
GameState GAME_STATE = GameState.INTRO;
int ITEM_STAGE_COMPLETE = 0;
int ITEMS_COUNT = 5;
int STAGE_COMPLETE_ITEMS_X = 450;
int STAGE_COMPLETE_ITEMS_Y = 150;
int STAGE_COMPLETE_ITEMS_ROW = 9;
int STAGE_MAX = 9;
int MOON_MAX = 8;

Player PLAYER;
ArrayList<Room> ROOMS = new ArrayList<Room>();
int ROOM_CURRENT_INDEX;
ArrayList<Item> ITEMS_COLLECTED = new ArrayList<Item>();
Stats GAME_STATS = new Stats();
HashMap<String, PImage> GAME_IMAGES = new HashMap<String, PImage>();
SoundFile BGM;

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

// Returns the number of itms in the stage based on the stage number
int getItemsCount(int stage) {
  switch (stage) {
    case 1: return 1;
    case 2: return 4;
    case 3: return 8;
    case 4: return 12;
    case 5: return 16;
    case 6: return 24;
    case 7: return 32;
    case 8: return 40;
    default: return 45;
  }
}

// Plays background music, switching tracks as needed
void updateBackgroundMusic() {
  if (BGM == null) {
    // This is the very first time a track is being played, which is also probably the tutorial level
    BGM = new SoundFile(this, "music/Tutorial.mp3");
  }
  if (!BGM.isPlaying()) {
    // Players can skip tracks if they progress fast enough before the current track ends.
    // Note that loading soundtracks is an expensive operation, so the game might pause a bit when this
    // happens mid-game. Loading all the tracks during setup results in much more noticeable startup
    // lag and presumably more system resource usage as well.
    switch (GAME_STATS.stage) {
      case 2:
      case 3:
        BGM = new SoundFile(this, "music/StageAfternoon.mp3");
        break;
      case 4:
      case 5:
        BGM = new SoundFile(this, "music/StageEvening.mp3");
        break;
      case 6:
      case 7:
        BGM = new SoundFile(this, "music/StageLateEvening.mp3");
        break;
      case 8:
      case 9:
        BGM = new SoundFile(this, "music/StageNightfall.mp3");
        break;
    }
    BGM.play();
  }
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
  Y_STAGE_COMPLETE = 0;
  
  // Generate a new set of rooms, conceptualised into a grid.
  int roomWidth = (GAME_STATS.stage + 1);
  int roomHeight = roomWidth;
  int totalRooms = roomWidth * roomHeight;
  for (int row = 0; row < roomHeight; row++) {
    for (int col = 0; col < roomWidth; col++) {
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
      
      // Since rooms are added sequentially, room creation must done one row at a time.
      // Creating the rooms per column causes warps to mess up, since adding a room
      // into the global variable sets its reference index as well.
      // (i.e. rooms are added in order of 0, 1, 2, ...
      // instead of directly adding a room at index 'roomCurrent')
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
  for (int i = ITEM_STAGE_COMPLETE + 1; i < getItemsCount(GAME_STATS.stage); i++) {
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
  
  if (GAME_STATS.isFirstStage()) {
    // Add tutorial text to various rooms for the first stage only
    String[] textTutorial = new String[]{
      "Press anywhere in the room to move to that location",
      "You can press on the doors to open and close them",
      "Closed doors will auto-lock if there are too many open"
    };
    ROOMS.get(ROOM_CURRENT_INDEX).addRoomText(String.join("\n", textTutorial));
    ROOMS.get(itemStageCompleteIndex).addRoomText("Get the serum & other items before it's full moon!");
  }
}

void setup() {
  size(960, 540);
  orientation(LANDSCAPE);
  surface.setIcon(loadImage("images/Moon8.png")); // This line must be removed if running on Android
  textFont(createFont("GOTHICB.TTF", 32));
  UNIT_X = 50;
  UNIT_Y = UNIT_X;
  X_MAX = width - X_MIN;
  Y_MAX = height - Y_MIN;
  GAME_IMAGES.put("LOCK_DISABLED", loadImage("images/LockDisabled.png"));
  GAME_IMAGES.put("LOCK_ENABLED", loadImage("images/LockEnabled.png"));
  GAME_IMAGES.put("CURE", loadImage("images/Cure.png"));
  GAME_IMAGES.put("GAME_OVER", loadImage("GameOver.png"));
  for (int i = 0; i <= MOON_MAX; i++) {
    GAME_IMAGES.put("MOON" + i, loadImage("images/Moon" + i + ".png"));
  }
  gameReset();
}

void mousePressed() {
  switch(GAME_STATE) {
    case INTRO:
      GAME_STATE = GameState.IN_GAME;
      updateBackgroundMusic();
      break;
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
      if (GAME_STATS.obtainedAllItems()) {
        GAME_STATE = GameState.GAME_WIN;
      } else if (GAME_STATS.stage >= STAGE_MAX) {
        GAME_STATE = GameState.GAME_LOSE;
      } else {
        GAME_STATE = GameState.IN_GAME;
        GAME_STATS.increaseStageAndReset();
        gameReset();
      }
      break;
    case GAME_WIN:
    case GAME_LOSE:
      break;
  }
}

// Draws a simple brick pattern
void drawBackground() {
  if (GAME_STATS.itemsRemaining < 16) {
    // Black bricks
    background(#000000);
    stroke(#7F7F7F);
  } else if (GAME_STATS.itemsRemaining < 32) {
    // Dark red bricks
    background(#880015);
    stroke(#FFFFFF);
  } else if (GAME_STATS.itemsRemaining < 48) {
    // Orange bricks with brown cement
    background(#E75A1E);
    stroke(#A5524A);
  } else {
    // Light brown bricks
    background(#C7A07A);
    stroke(#000000);
  }
  
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

// Returns a boolean value indicating whether the intermediate animation has completed
boolean drawBackgroundNight() {
  // Background darkens as the stages progress for that "full moon in the night" effect
  float darkFactor = float(MOON_MAX - GAME_STATS.stage) / MOON_MAX;
  color backgroundColour = color(63 * darkFactor, 72 * darkFactor, 204 * darkFactor);

  if (GAME_STATE == GameState.STAGE_COMPLETE) {
    if (Y_STAGE_COMPLETE < height) {
      // Draw a rectangle with the current background colour spanning a portion of the screen.
      // This constitutes the falling animation that plays after a stage is completed.
      rectMode(CENTER);
      fill(backgroundColour);
      noStroke();
      rectMode(CORNER);
      rect(0, 0, width, Y_STAGE_COMPLETE);
      
      Y_STAGE_COMPLETE += UNIT_Y;
      return false;
    }
  }
  
  // Animation has finished, so just draw the whole background
  background(backgroundColour);
  return true;
}

void introGameLoop() {
  background(0);
  
  fill(255, 255, 255);
  textSize(32);
  textAlign(CENTER, CENTER);
  text("""
Waking up one afternoon, you feel absolutely abysmal.
Being the knowledgeable druid you are, you figure it's
probably lycanthropy.
You'd better make a cure soon, especially since your
health insurance policy most definitely won't cover this.

Press anywhere on the screen to continue.
  """,
  width / 2, height / 2);
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
      int itemX = STAGE_COMPLETE_ITEMS_X + (UNIT_X * (ITEMS_COLLECTED.size() % STAGE_COMPLETE_ITEMS_ROW ));
      int itemY = STAGE_COMPLETE_ITEMS_Y + (UNIT_Y * (ITEMS_COLLECTED.size() / STAGE_COMPLETE_ITEMS_ROW ));
      ITEMS_COLLECTED.add(new Item(collectedItemId, itemX, itemY));
      if (collectedItemId == ITEM_STAGE_COMPLETE) {
        // Stage completes after collecting the necessary item
        GAME_STATS.registerItemsCollected(ITEMS_COLLECTED.size());
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
  boolean hasEntryTransitionFinished = drawBackgroundNight();
  if (!hasEntryTransitionFinished) {
    return;
  }
  
  fill(255, 255, 255);
  textSize(64);
  textAlign(CENTER);
  text("STAGE "+ GAME_STATS.stage + " COMPLETE!", width / 2, UNIT_Y);
  
  textSize(32);
  textAlign(LEFT);
  ArrayList<String> statsList = GAME_STATS.getStatsList();
  int statsY = int(height * 0.25);
  for (int s = 0; s < statsList.size(); s++) {
    text(statsList.get(s), X_MIN, statsY + (UNIT_Y * s));
  }
  
  for (int i = 0; i < ITEMS_COLLECTED.size(); i++) {
    ITEMS_COLLECTED.get(i).drawItem();
  }
  
  fill(255, 255, 255);
  textSize(32);
  textAlign(CENTER);
  text("Press the screen for the next stage", width / 2, Y_MAX);
  
  imageMode(CENTER);
  int moonImageIndex = min(GAME_STATS.stage - 1, MOON_MAX);
  image(GAME_IMAGES.get("MOON" + moonImageIndex), width * 0.3, height * 0.7, 60, 60);
}

void winGameLoop() {
  drawBackgroundNight();
  
  fill(255, 255, 255);
  textSize(64);
  textAlign(CENTER);
  text("The cure is complete!", width / 2, UNIT_Y);
  
  textSize(32);
  textAlign(LEFT);
  text("""
After cobbling together all these random items of
mystical origin, you've somehow conjured up a
cure for your lycanthropy...

Wait, it might have been leprosy. Or listeriosis?
Dang. You probably made a cure for the wrong
illness. Or maybe the journey was the real cure all
along? Hmm... nope, definitely the wrong cure.
  """,
  UNIT_X, UNIT_Y * 2);
  
  imageMode(CENTER);
  image(GAME_IMAGES.get("CURE"), width * 0.9, height * 0.5, 256, 256);
}

void loseGameLoop() {
  imageMode(CENTER);
  PImage img = GAME_IMAGES.get("GAME_OVER");
  image(img, width / 2, height  / 2, img.width * 2, img.height * 2);
  
  fill(255, 255, 255);
  textSize(64);
  textAlign(CENTER);
  text("Quest failed!", width / 2, height - UNIT_Y);
}

void draw() {
  switch(GAME_STATE) {
    case INTRO:
      introGameLoop();
      break;
    case IN_GAME:
      updateBackgroundMusic();
      mainGameLoop();
      break;
    case STAGE_COMPLETE:
      updateBackgroundMusic();
      stageCompleteLoop();
      break;
    case GAME_WIN:
      winGameLoop();
      break;
    case GAME_LOSE:
      loseGameLoop();
      break;
  }
}
