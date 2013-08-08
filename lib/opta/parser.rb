module Opta
  class Parser
    def initialize(file)
      @file = file
    end
    
    def doc 
      @doc ||=  Nokogiri.XML(File.open(File.join('public', @file), 'rb'))
    end
    
    def events
      @events ||= doc.xpath('./Games/Game/Event')
    end
  end
end
