# frozen_string_literal: true

logger.warn("Loading script #{__FILE__}")

module LockEvents
  MANUAL_LOCK = 1
  MANUAL_UNLOCK = 2
  REMOTE_LOCK = 3
  REMOTE_UNLOCK = 4
  KEYPAD_LOCK = 5
  KEYPAD_UNLOCK = 6
  MANUAL_NOT_FULLY_LOCKED = 7
  RF_NOT_FULLY_LOCKED = 8
  AUTO_LOCK = 9
  AUTO_LOCK_NOT_FULLY_LOCKED = 10
  LOCK_JAMMED = 11

  module Type
    ACCESS_CONTROL = "ACCESS_CONTROL"
  end

  KEYCODE = "parameter-1"
  NOTIFICATION = "notification"
end

# The following data is for reference as I dial in events
#
#   <options>
#     <option value="0">Previous Events cleared</option>
#     <option value="1">Manual Lock Operation</option>
#     <option value="2">Manual Unlock Operation</option>
#     <option value="3">RF Lock Operation</option>
#     <option value="4">RF Unlock Operation</option>
#     <option value="5">Keypad Lock Operation</option>
#     <option value="6">Keypad Unlock Operation</option>
#     <option value="7">Manual Not Fully Locked Operation</option>
#     <option value="8">RF Not Fully Locked Operation</option>
#     <option value="9">Auto Lock Locked Operation</option>
#     <option value="10">Auto Lock Not Fully Operation</option>
#     <option value="11">LockJammed</option>
#
#     <option value="12">All user codes deleted</option>
#     <option value="13">Single user code deleted</option>
#     <option value="14">New user code added</option>
#     <option value="15">New user code not added due to duplicate code</option>
#     <option value="16">Keypad temporary disabled</option>
#     <option value="17">Keypad busy</option>
#     <option value="18">New Program code Entered- Unique code for lock configuration</option>
#     <option value="19">Manually Enter user Access code exceeds code limit</option>
#     <option value="20">Unlock by RF with invalid user code</option>
#     <option value="21">Locked by RF with invalid user code</option>
#     <option value="22">Window/Door is open</option>
#     <option value="23">Window/Door is closed</option>
#     <option value="64">Barrier performing initialization process</option>
#     <option value="65">Barrier operation (Open / Close) force has been exceeded</option>
#     <option value="66">Barrier motor has exceeded manufacturer's operational time limit</option>
#     <option value="67">Barrier operation has exceeded physical mechanical limits</option>
#     <option value="68">Barrier unable to perform requested operation due to UL requirements</option>
#     <option value="69">Barrier Unattended operation has been disabled per UL requirements</option>
#     <option value="70">Barrier failed to perform Requested operation, device malfunction</option>
#     <option value="71">Barrier Vacation Mode</option>
#     <option value="72">Barrier Safety Beam Obstacle</option>
#     <option value="73">Barrier Sensor Not Detected / Supervisory Error</option>
#     <option value="74">Barrier Sensor Low Battery Warning</option>
#     <option value="75">Barrier detected short in WallStation wires</option>
#     <option value="76">Barrier associated with non-Z-wave remote control</option>
#   </options>
