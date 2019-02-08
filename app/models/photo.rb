class Photo
	require 'exifr/jpeg'

	attr_accessor :id, :location, :place
	attr_writer :contents

	def self.mongo_client
		Mongoid::Clients.default
	end

	def initialize(params = {})
		@id = params[:_id].to_s if !params[:_id].nil?
		@location = Point.new(params[:metadata][:location]) if !params[:metadata].nil?
    @place = params[:metadata][:place] if !params[:metadata].nil?
	end	

  def place
	   @place.nil? ? nil : Place.find(@place)
  end
  
  def place=(place)
    if place.is_a?(Place)
      @place =  BSON::ObjectId.from_string(place.id)
    else
      @place = BSON::ObjectId.from_string(place)
    end
  end	
  
	def persisted?
		!@id.nil?
	end

	def save
		if !self.persisted?
			gps = EXIFR::JPEG.new(@contents).gps
			@location = Point.new(:lng => gps.longitude, :lat => gps.latitude)
			@contents.rewind
			description = {}
			description[:metadata] = {}
			description[:metadata][:location] = @location.to_hash
			description[:metadata][:place] = @place
			description[:content_type] = "image/jpeg"
			grid_file = Mongo::Grid::File.new(@contents.read, description)
			id = self.class.mongo_client.database.fs.insert_one(grid_file)
			@id = id.to_s
		else
		  query = {}
		  query[:metadata] = {}
		  query[:metadata][:location] = @location.to_hash
		  query[:metadata][:place] = @place
		  self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id)).update_one(:$set=> query)
		end
	end

  def self.all(offset = 0, limit = nil)
		result = self.mongo_client.database.fs.find.skip(offset)
    result = result.limit(limit) if limit
    result.map { |doc| Photo.new(doc)}
  end

  def self.find id
  	result = self.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(id)).first
  	return result.nil? ? nil : Photo.new(result)
  end

  def contents
  	f = self.class.mongo_client.database.fs.find_one(:_id => BSON::ObjectId.from_string(@id))
    if f 
      buffer = ""
      f.chunks.reduce([]) do |x,chunk| 
          buffer << chunk.data.data 
      end
      return buffer
    end 
  end 

  def destroy
  	self.class.mongo_client.database.fs.find(:_id => BSON::ObjectId.from_string(@id)).delete_one
  end
  
  def find_nearest_place_id maximum_distance
    places = Place.near(@location, maximum_distance).limit(1).projection(:_id => 1)
    return places.first.nil? ? nil : places.first["_id"]
  end
  
  def self.find_photos_for_place place_id
    place_id = place_id.to_s
    self.mongo_client.database.fs.find('metadata.place' => BSON::ObjectId.from_string(place_id))
  end
end
