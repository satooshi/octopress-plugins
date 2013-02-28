require 'flickraw'

=begin
Square 75: s
Square 150: q
Thumbnail: t
Small 240: m
Small 320: n
Medium 500: no suffix
Medium 640: z
Medium 800: c
Large 1024: b
Large 1600: h
Large 2048: k
original: o
=end

# original idea is https://gist.github.com/danielres/3156265
class FlickrImage < Liquid::Tag
  def initialize(tag_name, markup, tokens)
    super
    @markup = markup
    @id     = markup.split(' ')[0]
    @size   = markup.split(' ')[1]
    @cache_folder = File.expand_path "../.flickr-cache", File.dirname(__FILE__)
    FileUtils.mkdir_p @cache_folder
  end

  def render(context)
    FlickRaw.api_key        = ENV["FLICKR_KEY"]
    FlickRaw.shared_secret  = ENV["FLICKR_SECRET"]

    gen_html_output
  end

  def gen_html_output
    data = get_cached_media(@id, 'info') || get_info(@id)
    info = Marshal.load(data)
    src  = gen_image_src info

    size_data = get_size_data @id, src

    #description = info['description']
    page_url   = info['urls'][0]['_content']
    exif_tag   = gen_exif_tag
    flickr_tag = gen_flickr_tag page_url
    img_tag    = gen_image_tag info, src, size_data
    link_tag   = "<div class=\"flickr-image\"><a href=\"#{page_url}\" target=\"_blank\">#{exif_tag}#{img_tag}</a>#{flickr_tag}</div>"
  end

  # cache

  def get_cached_media(id, suffix)
    cache_file = get_cache_file_for id, suffix
    File.read cache_file if File.exist? cache_file
  end

  def cache(id, data, suffix)
    cache_file = get_cache_file_for id, suffix
    File.open(cache_file, "w") do |io|
      io.write data
    end
  end

  def get_cache_file_for(id, suffix)
    File.join @cache_folder, "#{id}-#{suffix}.cache"
  end

  # tag

  def gen_image_tag(info, src, size_data)
    title = info['title']
    maxHeight = 640

    if size_data['landscape']
      maxHeight = size_data['height'] * maxHeight / size_data['width'] if size_data['width'] unless size_data['width'] == 0;
    end

    img_tag = "<img src=\"#{src}\" title=\"#{title}\" style=\"max-height:#{maxHeight.to_i}px;\">"
  end

  def gen_image_src(info)
    server      = info['server']
    farm        = info['farm']
    id          = info['id']
    secret      = info['secret']
    size        = "_#{@size}" if @size
    src         = "http://farm#{farm}.staticflickr.com/#{server}/#{id}_#{secret}#{size}.jpg"
  end

  def gen_flickr_tag(page_url)
    flickr_tag = "<p class=\"flickr-footer\"><a href=\"#{page_url}\" target=\"_blank\">www.<strong>flick<em>r</em></strong>.com</a></p>"
  end

  def gen_exif_tag
    exif_items = get_exif_items.join(', ')
    exif_tag = "<p class=\"flickr-exif\">" + exif_items + "</p>" unless exif_items.empty?
  end

  # info

  def get_info(id)
    info = flickr.photos.getInfo(:photo_id => id)
    data = Marshal.dump(info.to_hash)
    cache id, data, "info" unless @cache_disabled
    data
  end

  # sizes

  def get_sizes(id)
    sizes = flickr.photos.getSizes(:photo_id => id)
    data = Marshal.dump(sizes.to_hash)
    cache id, data, "sizes" unless @cache_disabled
    data
  end

  def get_size_data(id, src)
    data = get_cached_media(id, 'sizes') || get_sizes(id)
    sizes = Marshal.load(data)

    width, height, landscape, square = 0, 0, true, false

    for size in sizes['size']
      if src == size['source']
        width     = size['width'].to_i
        height    = size['height'].to_i
        landscape = width > height
        square    = width == height
        break
      end
    end

    {'width' => width, 'height' => height, 'landscape' => landscape, 'square' => square}
  end

  # exif

  def get_exif(id)
    info = flickr.photos.getExif(:photo_id => id)
    data = Marshal.dump(info.to_hash)
    cache id, data, "exif" unless @cache_disabled
    data
  end

  #Lens: raw = 17-50mm F2.8
  #FocalLength: clean 50 mm
  #FocalLengthIn35mmFormat: raw = 75mm
  #FNumber: clean = f/2.8
  #ISO: raw = 1600
  #ExposureTime: raw = 1/15
  #ExposureCompensation: clean = 0 EV
  #Software: raw = Aperture 3.4.1
  def get_exif_items
    data = get_cached_media(@id, 'exif') || get_exif(@id)
    exif = Marshal.load(data)

    if exif['camera'].empty?
      return []
    end

    exif_items = [exif['camera']];

    for item in exif['exif']
      case item['tag']
        when 'Lens'
          exif_items[1] = item['clean'] || item['raw']
        when 'FocalLength'
          exif_items[2] = item['clean'] || item['raw']
        when 'FocalLengthIn35mmFormat'
          exif_items[3] = item['raw'] + " (35mm format)" if item['raw']
        when 'FNumber'
          exif_items[4] = item['clean'] || item['raw']
        when 'ISO'
          exif_items[5] = "ISO " + item['raw'] if item['raw']
        when 'ExposureTime'
          exif_items[6] = item['raw'] + " sec" if item['raw']
        when 'ExposureCompensation'
          exif_items[7] = item['clean'] || item['raw']
        when 'Software'
          exif_items[8] = item['clean'] || item['raw']
      end
    end

    exif_items.compact!

    return exif_items
  end
end

Liquid::Template.register_tag('flickr_image', FlickrImage)
