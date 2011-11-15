require 'rubygems'
require 'rmagick'
include Magick

orig_image = Image.read("TokyoPanoramaShredded.png")

puts orig_image

slice_width = 32
puts "slice_width is #{slice_width}"

puts orig_image
num_slices = orig_image.columns / slice_width

puts "will cut image into #{num_slices} slices"

# cat = ImageList.new("TokyoPanoramaShredded.png")
# cat.display



# Shoes.app :width => 640, :height => 359 do
#    button("Click me!") { alert("Good job.") }
# 
#    image "TokyoPanoramaShredded.png", :top => 0, :left => 0
# 
# 
# 
# end
# 
