class Asset < ActiveRecord::Base
  include Magick
  
  cattr_accessor :thumbnail_width, :thumbnail_height

  validates_presence_of :project_id, :path
  validates_associated :project

  belongs_to :project
    
  acts_as_taggable

  # Starts with '/' but is relative to 'public'
  @@asset_dir = '/system/assets'

  @@thumbnail_width = 200
  @@thumbnail_height = 120

  # Returns the full path to this asset on disk. /Users/bert/photos/pigeon.jpg
  # TODO Take size argument
  def absolute_path(size=:normal)
    File.expand_path("public#{self.web_path(size)}", RAILS_ROOT)
  end

  # :thumb, :normal, :original
  def web_path(size=:normal)
    if size == :original
      return path
    else
      path.gsub /(\..*?)$/, "_#{size.to_s}\\1"
    end
  end


  # Called automatically when saved from HTML forms
  def file_field=(file_field)
    if !file_field.original_filename.blank?
      # Make sure the directory exists for us to save into
      FileUtils.mkdir_p(File.expand_path("public#{@@asset_dir}", RAILS_ROOT))

      # Set file to unique timestamp plus original extension
      self.path = "#{@@asset_dir}/#{Time.now.utc.to_i}." + file_field.original_filename.gsub(/.*\./, '')
      File.open(self.absolute_path(:original), File::CREAT|File::WRONLY) { |f| f.write(file_field.read) }

      self.resize_thumbnail
      self.resize_normal
    end
  end


  def resize_thumbnail
    image = Image.read(self.absolute_path(:original)).first
    #geo_string = if (image.rows.to_f/image.columns.to_f) >= (@@thumbnail_width.to_f/@@thumbnail_height.to_f)
    #   # Wider than tall...use height
    #   "x#{@@thumbnail_height}"
    # else
    #   "#{@@thumbnail_width}x"
    # end
    image.change_geometry("#{@@thumbnail_width}x#{@@thumbnail_height}>") do |w, h, i|
      i.resize!(w, h)
      i.crop(0, 0, @@thumbnail_width, @@thumbnail_height)
    end
    
    image.write(File.expand_path("public#{self.web_path(:thumb)}", RAILS_ROOT))
  end


  def resize_normal
    image = Image.read(self.absolute_path(:original)).first
    image.change_geometry('640x480>'){|w, h, i| i.resize!(w, h)}
    # TODO Refactor
    image.write(File.expand_path("public#{self.web_path(:normal)}", RAILS_ROOT))
  end


  def before_destroy
    [:original, :normal, :thumb].each do |size|
      begin
        File.delete absolute_path(size)
      rescue Errno::ENOENT => e
      end
    end
  end

  def rotate(direction='cw')
    degrees = 90
    if direction == 'ccw'
      degrees = -90
    end
    image = Image.read(self.absolute_path(:original)).first
    image.rotate! degrees

    image.write(File.expand_path("public#{self.web_path(:original)}", RAILS_ROOT))

    resize_thumbnail
    resize_normal
  end

  # Returns the file extension, like jpg or pdf
  def extension
    self.path.gsub(/.*\./, '')
  end

  # Returns the http Content-Type (image/png, etc.)
  #
  # TODO Add more types, or get from a reference
  def file_type
    file_types = {
      /jpe?g/i => 'image/jpeg',
      /png/ => 'image/png',
      /gif/ => 'image/gif'
    }
    file_types.keys.each do |k|
      if k.match(self.extension)
        return file_types[k]
      end
    end
    nil
  end

protected

  # Fixes a 'feature' of IE where it passes the entire path instead of just the filename
  def sanitize_filename(value)
      #get only the filename, not the whole path
      just_filename = value.gsub(/^.*(\\|\/)/, '')
      #NOTE: File.basename doesn't work right with Windows paths on Unix
      #INCORRECT: just_filename = File.basename(value.gsub('\\\\', '/')) 
      #replace all none alphanumeric, underscore or periods with underscore
      just_filename.gsub(/[^\w\.\-]/,'_') 
  end

end
