require 'rubygems'
require 'rmagick'
require 'logger'
include Magick


class Unshredder
  attr_accessor :shredded_image
  attr_accessor :unshredded_image
  attr_reader :slice_width
  attr_reader :sorted_variants
  
  def initialize(filename)
    @shredded_image = Image.read(filename).first
    
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::INFO

    @diffs = Hash.new
             
    init_diffs
    
    @sorted_diffs = @diffs.sort { |a,b| a[1] <=> b[1] }

    @unshredded_slices = Array.new()
    
    # take best guess
    
    @best_diffs = @sorted_diffs.slice(0, 1)
    
    @variants = Hash.new
    
    @best_diffs.each do |key, diff_value|
      (left, right) = key.split('-')

      variant_diff = diff_value
      variant_slices = Array.new
      while variant_slices.count < slice_count
        # fill slice slots staring with current item
        if variant_slices.empty?
          variant_slices << left
          variant_slices << right
        else
          neigbor = next_neigbor(variant_slices)
          (n_left, n_right) = neigbor.split('-')
          if (n_left == variant_slices.last)
            # new neigbor to the right
            variant_slices << n_right
            variant_diff += @diffs[neigbor]
          else 
            if n_right == variant_slices.first
              # new neigbor to the left
              variant_slices = variant_slices.unshift(n_left)
              variant_diff += @diffs[neigbor]
            end
          end
        end
      end
      variant_key = variant_slices.join('-')
      @variants[variant_key] = variant_diff
    end
    
    @sorted_variants = @variants.sort { |a,b| a[1] <=> b[1] }

    p @sorted_variants
    
  end
  
  def unshredded_image(variant)
    il = ImageList.new
  
    pos = 0
    variant[0].split('-').each do |slice_index|
      il << @shredded_image.crop(slice_index.to_i*slice_width, 0, slice_width, image_height)
      pos += 1
    end
    
    return il.append(false)
  end
  
  def next_neigbor(current_slices)
    left = current_slices.first
    right = current_slices.last
    
    @sorted_diffs.each do |dkey, dval|
      (dleft, dright) = dkey.split('-')
      if right == dleft && !current_slices.include?(dright)
        return dkey
      end
      
      if left == dright && !current_slices.include?(dleft)
        return dkey
      end
      
    end
  end

  def init_diffs
    0.upto(slice_count-1) do |slice_left|
       0.upto(slice_count-1) do |slice_right|
        unless slice_left == slice_right
          @diffs["#{slice_left}-#{slice_right}"] = match_slices(slice_left, slice_right)
        end
      end
    end
  end
    
  def match_slices(slice_left, slice_right)
    # slice_left is left of slice_right
    # check right border of slice1 to left border of slice2
    x1 = slice_left*slice_width+slice_width-1
    x2 = slice_right*slice_width
    edge_diff_value(x1, x2)
  end
  
  def edge_diff_value(x1, x2)
    egde_diff = 0
    (image_height-1).times do |y|
      p1 = @shredded_image.pixel_color(x1, y)
      p2 = @shredded_image.pixel_color(x2, y)

      rd = p1.red-p2.red
      gd = p1.green-p2.green
      bd = p1.blue-p2.blue
      od = p1.opacity-p2.opacity

      diff = Math.sqrt(rd*rd + gd*gd + bd*bd + od*od)

      diff = diff < 2000 ? 0 : 1

      egde_diff += diff
    end
    # log "edge diff at #{x1}, #{x2} is #{egde_diff}"
    egde_diff
  end

  
  def log(s)
    @logger.info s
  end
  
  def image_height
    @shredded_image.rows
  end

  def image_width
    @shredded_image.columns
  end

  def slice_width
    32
  end
  
  def slice_count
    (image_width / slice_width).abs
  end

end

unshredder = Unshredder.new("TokyoPanoramaShredded.png")

unshredder.sorted_variants.each do |variant|
  unshredder.unshredded_image(variant).display
end