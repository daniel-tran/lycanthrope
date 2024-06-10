class Stats {
  ArrayList<String> results = new ArrayList<String>();
  int stage;
  int doorsUnlocked;
  int doorsLocked;
  int roomsTraversed;
  
  Stats() {
    stage = 1;
    reset();
  }
  
  // Clears all the game statistics and stored result strings
  void reset() {
    results.clear();
    doorsUnlocked = 0;
    doorsLocked = 0;
    roomsTraversed = 0;
  }
  
  // Returns the game statistics as a list of strings summarising each metric.
  ArrayList<String> getStatsList() {
    // To avoid having to recalculate these values all the time, it is only done
    // once since the game isn't being played while on the stage completion screen.
    if (results.size() <= 0) {
      results.add("Doors unlocked: " + doorsUnlocked);
      results.add("Doors locked: " + doorsLocked);
      results.add("Rooms traversed: " + roomsTraversed);
    }
    return results;
  }
  
  // A variation of reset() which also modifies the stage count
  void increaseStageAndReset() {
    stage++;
    reset();
  }
  
  // The below functions handle the incrementing of various game statistics
  
  void registerDoorUnlock() {
    doorsUnlocked++;
  }
  
  void registerDoorLock() {
    doorsLocked++;
  }
  
  void registerRoomTraverse() {
    roomsTraversed++;
  }
}
