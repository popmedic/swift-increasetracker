import Foundation

/**
 Tracks increases to a value based on the offset. Set the offset to start with, will default to 0. Call update
 periodiacally to set the new value based of the change from the last offset.
 
 Uses an Increase type for storing the increases, and a Offset type for the value that will update.  This allows
 the tracker to update with a smaller value, but store the value in a larger  value, handling when the
 increased value rolles over in the source.
 
 **Use Case** - Situations where you want to track changes to a value that is stored in a small int type, and
 worry it will "roll over" and loose track of the increase.
 */
public protocol IncreaseTrackable {
    /// Type to store the increased value
    associatedtype Track
    /// Type that is used to updating.  this will be smaller then the Track type, allowing increased to continue
    /// tracking when the source rolls over
    associatedtype Update
    /**
     Required initializer.
     - parameters:
        - offset: starting value for the offset
     - returns: a new IncreaseTrackable
     */
    init(_ offset: Update) throws
    /// Amount value has changed from the initial offset
    var increased: Track { get }
    /// Current offset, will roll over when Updates MAX has been reached
    var offset: Update { get }
    /**
     Updates the increased value
     
     If the value passed in is less then the current offset this indicates that the source has rolled around,
     will currectly adjust and update the increased variable correctly.
     
     **NOTE: ** this DOES run the possiblity of rolling over multiple times.  To improve accuracy update
     from the source often
     
     - parameters:
        - value: the new value from the source to calculate the increase from.
     - returns: the new increased value
     */
    func update(_ value: Update) throws -> Track
}

/**
 Tracks increases to a value based on the offset. Set the offset to start with, will default to 0. Call update
 periodiacally to set the new value based of the change from the last offset.
 
 Uses an Increase type for storing the increases, and a Offset type for the value that will update.  This allows
 the tracker to update with a smaller value, but store the value in a larger  value, handling when the
 increased value rolles over in the source.
 
 **Use Case** - Situations where you want to track changes to a value that is stored in a small int type, and
 worry it will "roll over" and loose track of the increase.
 
 - note: Will not work to track UInt or UInt64 because those will never meet the use case, as they are the
 largest UInt value types.
 
 **Example**
 
 Lets say we have a source that is a UInt8, but this value will roll over when it reaches 255, and we have no
 way to start this value at 0 so we need to start with the sources current offset to track the increases.
 
 We want to track it and we want to make sure that when the value gets greater then 255 we continue tracking.
 
 We can use a UInt64 for the `Track` type, and of course the `Update` will be based on the souce and in
 this example is a UInt8.
 
```
// protocol for the source
protocol Source {
var currentCount: UInt8
}

let source: Source = SourceImpl()

// if we want to use a timer to say every 15 seconds and continue tracking
// the `currentCount` even if it rolls around, we could do the following
let increaseTracker: IncreaseTracker<UInt64, UInt8>(source.currentCount)
let timer = Timer.scheduledTimer(withTimeInterval: 15,
                              repeats: true) { _ in
    increaseTracker.update(source.currentCount)
}
 
// when we would like to see the amount increased we can just do
print(increaseTracker.increased)
// it will print how much we have increase since we initialized.
```
 */
public class IncreaseTracker<
    Track: FixedWidthInteger & UnsignedInteger,
    Update: FixedWidthInteger & UnsignedInteger
>: IncreaseTrackable {
    /**
     Errors thrown
     */
    public enum Error: Swift.Error {
        case
        /// thrown when initializing and the Track type is smaller or equal to the Update type
        trackTypeMaxLessThenUpdateMax,
        /// thrown when update increase grows the increased value greater then Track type
        totalOutOfBounds
    }
    
    /**
     - parameters:
        - offset: starting value for the offset
     - returns: a new IncreaseTracker
     - throws: Error.trackTypeMaxLessThenUpdateMax if Tracker type is smaller then Update type
     */
    required public init(_ offset: Update = 0) throws {
        // make sure that the total type is smaller then the input type
        guard Track.max > Update.max else {
            throw Error.trackTypeMaxLessThenUpdateMax
        }
        
        let prefix = "\(Self.self)"
        updateAccessQueue = DispatchQueue(label: "\(prefix).updateAccessQueue")
        
        _offset = offset
        _increased = 0
    }
    
    /// Amount value has changed from the initial offset
    public var increased: Track { updateAccessQueue.sync { _increased } }
    /// Current offset, will roll over when Updates MAX has been reached
    public var offset: Update { updateAccessQueue.sync { _offset } }
    
    /**
    Updates the increased value
    
    If the value passed in is less then the current offset this indicates that the source has rolled around,
    will currectly adjust and update the increased variable correctly.
    
    - note: this DOES run the possiblity of rolling over multiple times without being caught.
     To improve accuracy update from the source often
    
    - parameters:
       - value: the new value from the source to calculate the increase from.
    - returns: the new increased value
    - throws: Error.totalOutOfBounds when increase grows greater then Track type
    */
    @discardableResult
    public func update(_ value: Update) throws -> Track {
        return try updateAccessQueue.sync { () throws -> Track in
            var _value = value
            
            // see if we are rolling over
            if _offset > _value {
                _value += (Update.max - _offset)
            } else {
                _value -= _offset
            }
            
            // set offset
            _offset = value
            
            // make sure that the result is in bounds
            guard isResultInBounds(_value) else {
                throw Error.totalOutOfBounds
            }
            
            // set total
            _increased = _increased + Track(_value)
            
            // return the total
            return _increased
        }
    }
    
    private func isResultInBounds(_ value: Update) -> Bool {
        return Double(_increased)/2.0 + Double(value)/2.0 <= Double(Track.max)/2.0
    }
    
    private let updateAccessQueue: DispatchQueue
    private var _increased: Track
    private var _offset: Update
}
