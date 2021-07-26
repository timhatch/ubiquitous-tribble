# frozen_string_literal: true

module TimerStrategy
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

    def self.reset(_climbing)
      0
    end
  end

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

    def self.reset(climbing)
      climbing
    end
  end
end

# A simple one-shot timer implementation
class Timer
  attr_reader :seconds

  STRATEGIES = {
    'countdown' => TimerStrategy::Countdown,
    'rotation' => TimerStrategy::Rotation,
    'elapsed' => TimerStrategy::Elapsed
  }

  def initialize(strategy:, rotation:, climbing:, start_at: nil)
    @rotation = rotation
    @climbing = climbing
    @strategy = STRATEGIES[strategy]

    @start_at = start(start_at)
    @seconds  = @strategy.reset(@climbing)
  end

  def run
    loop do
      # Calculate the elapsed time of the rotation
      # calculate the remaining time
      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_at

      # allow external processing of computed data
      @seconds = @strategy.seconds(@seconds, elapsed, @rotation, @climbing)
      yield if block_given?

      # Calculate the timeout interval and sleep the thread
      sleep(1.0 - elapsed.remainder(1))
    end
  end

  def restart!
    @seconds  = @strategy.reset(@climbing)
    @start_at = start(nil)
    yield if block_given?
  end

  # Getter
  def strtime
    s = @seconds.round
    "#{format('%02d', s / 60)}:#{format('%02d', s % 60)}"
  end

  # Set the monotonic startime.
  # If no time is given, return the current time
  # If a time is given, set the start time with an offset into the future
  def start(start_at)
    Process.clock_gettime(Process::CLOCK_MONOTONIC) +
      (start_at.nil? ? 0.0 : [Time.parse(start_at) - Time.now, 0.0].max)
  rescue ArgumentError, TypeError => e
    puts "Error: #{e}"
    exit
  end
end
