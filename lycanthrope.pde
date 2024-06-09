int X_MIN = 25;
int X_MAX = X_MIN;
int Y_MIN = 25;
int Y_MAX = Y_MIN;

Player PLAYER;
ArrayList<Room> ROOMS = new ArrayList<Room>();
int ROOM_CURRENT_INDEX = 4;

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

void keyPressed() {
  String keyCap = String.valueOf(Character.toUpperCase(key));
  switch(keyCap) {
    case "W":
    case "E":
    case "S":
    case "N":
      println("Setting room status for " + ROOM_CURRENT_INDEX + " & " + ROOMS.get(ROOM_CURRENT_INDEX).warpMap.get(keyCap));
      
      if (ROOMS.get(ROOM_CURRENT_INDEX).canToggleDoor(keyCap)) {
        // Lock/Unlock the door from both sides
        println("Toggling doors for " + keyCap + " & " + getOppositeDirection(keyCap));
        ROOMS.get(ROOM_CURRENT_INDEX).doors.get(keyCap).toggleLocked();
        ROOMS.get(ROOMS.get(ROOM_CURRENT_INDEX).warpMap.get(keyCap)).doors.get(getOppositeDirection(keyCap)).toggleLocked();
      }
      
      break;
  }
  println(keyCap);
}

void setup() {
  size(960, 540);
  X_MAX = width - X_MIN;
  Y_MAX = height - Y_MIN;
  PLAYER = new Player(width / 2, height / 2, 5, 5);
  PLAYER.setTravelBoundaries(X_MIN, X_MAX, Y_MIN, Y_MAX);
  ROOMS.add(new Room(6, 1, 3, 2));
  ROOMS.add(new Room(7, 2, 4, 0));
  ROOMS.add(new Room(8, 0, 5, 1));
  
  ROOMS.add(new Room(0, 4, 6, 5));
  ROOMS.add(new Room(1, 5, 7, 3));
  ROOMS.add(new Room(2, 3, 8, 4));
  
  ROOMS.add(new Room(3, 7, 0, 8));
  ROOMS.add(new Room(4, 8, 1, 6));
  ROOMS.add(new Room(5, 6, 2, 7));
  
  swapWarps(4, 0, "E", "W");
  
  for (int r = 0; r < ROOMS.size(); r++) {
    ROOMS.get(r).setDoors(X_MIN, X_MAX, Y_MIN, Y_MAX);
  }
}

void mousePressed() {
  println(mouseX + ", " + mouseY);
  // Keep the player within a certain border of the room
  if (mouseX > X_MIN && mouseX < X_MAX && mouseY > Y_MIN && mouseY < Y_MAX) {
    PLAYER.setDestination(mouseX, mouseY);
  }
  println("You are in room " + ROOM_CURRENT_INDEX);
}

void draw() {
  background(128, 128, 0);
  if (PLAYER.isMoving) {
    PLAYER.doTravel();
  }
  String warpKey = PLAYER.detectRoomTravel(ROOMS.get(ROOM_CURRENT_INDEX).doors);
  if (warpKey.length() > 0) {
    ROOM_CURRENT_INDEX = ROOMS.get(ROOM_CURRENT_INDEX).warpMap.get(warpKey);
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
