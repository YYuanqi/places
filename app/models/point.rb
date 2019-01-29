class Point
  attr_accessor :longitude, :latitude
  
  def to_hash
    hash = {}
    hash[:type] = "Point"
    hash[:coordinates] = [@longitude, @latitude]
    return hash
  end
  
  def initialize(params = {})
    if params[:coordinates]
      @longitude = params[:coordinates][0]
      @latitude = params[:coordinates][1]
    else
      @longitude = params[:lng]
      @latitude = params[:lat]
    end
  end
end
          