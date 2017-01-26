module LegendasTV
  class Medium
    attr_reader :id, :title, :type, :season

    def initialize(json)
      @id     = json[:id_filme]
      @title  = json[:dsc_nome]
      @type   = json[:tipo]
      @season = json[:temporada].to_i unless json[:temporada].to_s.empty?
    end

    def type
      case @type
      when 'S' then :series
      when 'M' then :movie
      else :unknown
      end
    end
  end
end
