# swift-increasetracker

 Tracks increases to a value based on the offset. Set the offset to start with, will default to 0. Call update
 periodiacally to set the new value based of the change from the last offset.
 
 Uses an Increase type for storing the increases, and a Offset type for the value that will update.  This allows
 the tracker to update with a smaller value, but store the value in a larger  value, handling when the
 increased value rolles over in the source.
 
 **Use Case** - Situations where you want to track changes to a value that is stored in a small int type, and
 worry it will "roll over" and loose track of the increase.
