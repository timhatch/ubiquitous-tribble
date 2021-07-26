# frozen_string_literal: true

module Timer
  module Strategy
    # One shot countdown timer: decrements the clock until the climbing time is finished.
    # If the current time is positive, return the climbing time less the elapsed time
    # (auto decrementing via the calling loop). Otherwise return the current time
    class Countdown
      def self.seconds(current, elapsed, _rotation, climbing)
        if current.positive?
          climbing - elapsed
        else
          current
        end
      end

      # Reset the clock
      # By default reset to the climbing time
      def self.reset(climbing)
        climbing
      end
    end

    # Repeating countdown timer: Use remainder to get the time remaining in the current rotation.
    # If the remaining time is less than the climbing time, return the climbing time less the
    # elapsed time, otherwise return the rotation time less the elapsed time (i.e. the amount of
    # recuperation time remaining). Aauto decrementing via the calling loop).
    class Rotation
      def self.seconds(_current, elapsed, rotation, climbing)
        remaining = elapsed.remainder(rotation)
        (remaining <= climbing ? climbing : rotation) - remaining
      end

      # Reset the clock
      # By default reset to the climbing time
      def self.reset(climbing)
        climbing
      end
    end

    # One shot elapsed timer: decrements the clock until the climbing time is finished.
    # If the elapsed time exceeds the climbing time, return the climbing time
    # therwise return the elapsed time (auto incrementing via the calling loop).
    # FIXME: Does not handle future start times
    class Elapsed
      def self.seconds(_current, elapsed, _rotation, climbing)
        if elapsed.to_i > climbing
          climbing
        else
          elapsed
        end
      end

      # Reset the clock
      # By default reset to zero
      def self.reset(_climbing)
        0
      end
    end
  end
end
