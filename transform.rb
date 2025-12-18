require 'asciidoctor/extensions'

class FixCaptionSpacing < Asciidoctor::Extensions::Treeprocessor
  def process(document)
    document.find_by { |n| n.respond_to?(:caption) && (cap = n.caption) && !cap.empty? }.each do |node|
      cap = node.caption
      new_cap = cap.gsub(/\. (\d)/, '.\1')
      if new_cap != cap
        node.caption = new_cap
      end
    end
    document
  end
end

class FixXrefsSpacing < Asciidoctor::Extensions::Treeprocessor
  TARGET_CONTEXTS = [:listing, :image, :table]

  def process(document)
    document.find_by { |n| n.respond_to?(:xreftext) }.each do |node|
      begin
        raw = node.xreftext('short') || node.xreftext(nil) || node.xreftext('basic')
      rescue
        raw = nil
      end
      next if raw.nil? || raw.to_s.strip.empty?

      normalized = raw.to_s.gsub(/\. (\d)/, '.\1')

      # For tables, use the full caption (with number) as reftext, but remove trailing period
      if node.context == :table && node.respond_to?(:caption) && node.caption
        normalized = node.caption.strip.sub(/\.$/, '')
      end

      node.attributes['reftext'] = normalized
    end
    document
  end
end


Asciidoctor::Extensions.register do
  treeprocessor FixCaptionSpacing
  treeprocessor FixXrefsSpacing
end