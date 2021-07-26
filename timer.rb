# frozen_string_literal: true

require_relative 'timer_strategy'

# A simple one-shot timer implementation
module Timer
  class Clock
    attr_reader :seconds

    def initialize(strategy:, rotation:, climbing:, start_at: nil)
      @start_at = self.class.start(start_at)
      @strategy = self.class.strat(strategy)

      @rotation = rotation
      @climbing = climbing
      @seconds  = @strategy.reset(@climbing)
    end

    def run
      loop do
        # Calculate the elapsed time of the rotation
        # Update the display time (@seconds)
        elapsed  = Process.clock_gettime(Process::CLOCK_MONOTONIC) - @start_at
        @seconds = @strategy.seconds(@seconds, elapsed, @rotation, @climbing)

        # allow external processing of computed data
        yield if block_given?

        # Calculate the timeout interval and sleep the thread
        sleep(1.0 - elapsed.remainder(1))
      end
    end

    def restart!
      @seconds  = @strategy.reset(@climbing)
      @start_at = self.class.start(nil)
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
    def self.start(start_at)
      Process.clock_gettime(Process::CLOCK_MONOTONIC) +
        (start_at.nil? ? 0.0 : [Time.parse(start_at) - Time.now, 0.0].max)
    rescue ArgumentError, TypeError => e
      puts "Error: #{e}"
      exit
    end

    def self.strat(type)
      {
        'countdown' => Timer::Strategy::Countdown,
        'rotation' => Timer::Strategy::Rotation,
        'elapsed' => Timer::Strategy::Elapsed
      }[type]
    end
  end
end
