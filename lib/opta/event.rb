module Opta
  
  class Event
    
    #element = XPath element 
    def initialize(element)
      @element = element
    end
    
    def attributes
      @attributes ||= @element.attributes
    end
    
    def x
      attributes['x'].value
    end
    
    def y
      attributes['y'].value
    end
    
    #Either 1 or 2
    def period_id
      attributes['period_id'].value.to_i
    end
    
    #These correspond to real event_ids
    def type_id
      attributes['type_id'].value.to_i
    end
    
    def team_id
      attributes['team_id'].value.to_i
    end
    
  end
end
