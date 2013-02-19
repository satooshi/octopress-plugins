class Spaceless < Liquid::Block
  def render(context)
    output = super

    %|#{output.gsub(/\>\s+\</, '><')}|
  end
end

Liquid::Template.register_tag('spaceless', Spaceless)
