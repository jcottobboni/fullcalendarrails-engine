module FullcalendarEngine
  class Event < ActiveRecord::Base

    attr_accessor :period, :frequency, :commit_button

    validates :title, :description, :presence => true
    validate :validate_timings

    belongs_to :event_series

    REPEATS = {
      :no_repeat => "Nao se repete",
      :days      => "Diario",
      :weeks     => "Semanal",
      :months    => "Mensal",
      :years     => "Anual"
    }

    def validate_timings
      if (starttime >= endtime) and !all_day
        errors[:base] << "Start Time must be less than End Time"
      end
    end

    def update_events(events, event)
      events.each do |e|
        begin
          old_start_time, old_end_time = e.starttime, e.endtime
          e.attributes = event
          if event_series.period.downcase == 'mensal' or event_series.period.downcase == 'anual'
            new_start_time = make_date_time(e.starttime, old_start_time)
            new_end_time   = make_date_time(e.starttime, old_end_time, e.endtime)
          else
            new_start_time = make_date_time(e.starttime, old_end_time)
            new_end_time   = make_date_time(e.endtime, old_end_time)
          end
        rescue
          new_start_time = new_end_time = nil
        end
        if new_start_time and new_end_time
          e.starttime, e.endtime = new_start_time, new_end_time
          e.save
        end
      end

      event_series.attributes = event
      event_series.save
    end

    private

      def make_date_time(original_time, difference_time, event_time = nil)
        DateTime.parse("#{original_time.hour}:#{original_time.min}:#{original_time.sec}, #{event_time.try(:day) || difference_time.day}-#{difference_time.month}-#{difference_time.year}")
      end
  end
end
