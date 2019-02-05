class Photo
	require 'exifr/jpeg'

	attr_accessor :id, :location
	attr_writer :contents

	def self.mongo_client
		Mongoid::Clients.default
	end

	def initialize(params = {})
		@id = params[:_id].to_s if !params[:_id].nil?
		@location = Point.new(params[:metadata][:location]) if !params[:metadata].nil?
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
			description[:content_type] = "image/jpeg"
			grid_file = Mongo::Grid::File.new(@contents.read, description)
			id = self.class.mongo_client.database.fs.insert_one(grid_file)
			@id = id.to_s
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
end
