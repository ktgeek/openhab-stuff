# frozen_string_literal: true

ensure_states!

# We don't know how long it takes to warm to temp like the nest did, so we're going to go for a half hour before we want
# temp
every :monday, :tuesday, :wednesday, :thursday, :friday, at: "6am" do
  FF_Thermostat_Min_Set_Point.command(73)
end

every :monday, :tuesday, :wednesday, :thursday, :friday, at: "10pm" do
  FF_Thermostat_Min_Set_Point.command(65)
end

every :saturday, :sunday, at: "7:30am" do
  FF_Thermostat_Min_Set_Point.command(73)
end

every :saturday, :sunday, at: "10:45pm" do
  FF_Thermostat_Min_Set_Point.command(65)
end
