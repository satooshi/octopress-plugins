class Spaceless < Liquid::Block
  def render(context)
    output = super

    %|#{output.gsub(/>\s+</, '><').gsub(/\s+<\!/,'<!').gsub(/<\/html>\s+/, '</html>')}|
  end
end

Liquid::Template.register_tag('spaceless', Spaceless)
