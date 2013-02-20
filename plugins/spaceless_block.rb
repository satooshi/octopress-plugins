require 'uuid'

class Spaceless < Liquid::Block
  def render(context)
    output = super

    uuid = UUID.new
    regex = /((<pre\s+.*>|<pre>)(?!.*(<pre\s+.*>|<pre>).*<\/pre>.*).*<\/pre>)/miu

    hash = Hash.new

    while !output.scan(regex).empty?
      replace = '___pre___' + uuid.generate

      output.sub!(regex, replace)
      hash[replace] = $&
    end

    output.gsub!(/>\s+</, '><').gsub(/\s+<\!/,'<!').gsub(/<\/html>\s+/, '</html>')

    hash.each{|key, value|
      output.sub!(key, value)
    }

    %|#{output}|
  end
end

Liquid::Template.register_tag('spaceless', Spaceless)
