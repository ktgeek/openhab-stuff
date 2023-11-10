# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

module Kwikset
  # http://s7d5.scene7.com/is/content/BDHHI/ApplicationNote-UsingASCII-Z-Wave-Locks
  # Alarm Type  Alarm Level       Notification Event
  # 017         001               Lock Secured at Keypad – Bolt Jammed (Not fully extended)
  # 018         000 or User-ID#*  Lock Secured at Keypad – Successful (Fully extended)
  # 019         User-ID#*         Lock Un-Secured by User (User-ID) at Keypad
  # 021         001               Lock Secured using Keyed cylinder or inside thumb-turn
  # 022         001               Lock Un-Secured using Keyed cylinder or inside thumb-turn
  # 023         001               Lock Secured by Controller – Bolt Jammed (Not fully extended)
  # 024         001               Lock Secured by Controller – Successful (Fully extended)
  # 025         001               Lock Un-Secured by Controller – Successful (Fully retracted)
  # 026         001               Lock Auto Secured – Bolt Jammed (Not fully extended)
  # 027         001               Lock Auto Secured – Successful (Fully extended)
  # 032         001               All User Codes deleted from lock
  # 112         User-ID#*         New User Code (User-ID#) added to the lock
  # 161         001               Failed User Code attempt at Keypad
  # 162         User-ID#*         Attempted access by user (User-ID#) outside of scheduled
  # 167         001               Low battery level
  # 168         001               Critical battery level
  # 169         001               Battery level too low to operate lock

  module Alarm
    KEYPAD_JAMMED = 17
    KEYPAD_LOCK = 18
    MANUAL_LOCK = 21
    MANUAL_UNLOCK = 22
    REMOTE_JAMMED = 23
    REMOTE_UNLOCK = 24
    REMOTE_LOCK = 25
    AUTO_JAMMED = 26
    AUTO_LOCK = 27
    NEW_USER_CODE = 112
    FAILED_USER_CODE = 161
    UNSCHEDULED_USER_CODE = 162
    LOW_BATTERY = 167
    CRITICAL_BATTERY = 168
    BATTERY_TOO_LOW = 169
  end
end
