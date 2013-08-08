#Given a csv row, parse out the data
class RowParser
  
  attr_reader :provider_id
  def initialize(row)
    @row = row
  end
  
  def parse
    @drg_desc = @row[0]
    @state_name = @row[1]
  end
  
  def drg
    DiagnosticRelatedGroup.where(:definition => @drg_desc).first_or_create
  end
  
  def state
    State.where(:abbreviation => @state_name).first_or_create
  end
  
  def solution
    log = [
        {time: 201201, x: 2},
        {time: 201201, y: 7},
        {time: 201201, z: 2},
        {time: 201202, a: 3},
        {time: 201202, b: 4},
        {time: 201202, c: 0}
      ]
    r = log.inject({}) do |result, record|
      time = record.delete(:time)
      if result.has_key?(time)
        result[time].merge!(record)
      else
        result[time] = record
      end
      result
    end
    r.to_a.inject([]) {|arr, res| arr << {time: res[0]}.merge!(res[1]); arr}
  end
      


end
