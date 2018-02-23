require 'asciidoctor/extensions'

module Asciidoctor
  module ISO
    module Inline

      def is_refid?(x)
        @refids.include? x
      end

      def inline_anchor(node)
        case node.type
        when :ref
          inline_anchor_ref node
        when :xref
          inline_anchor_xref node
        when :link
          inline_anchor_link node
        when :bibref
          inline_anchor_bibref node
        else
          Utils::warning(node, "unknown anchor type", node.type.inspect)
        end
      end

      def inline_anchor_ref(node)
        noko do |xml|
          xml.bookmark nil, **attr_code(id: node.id)
        end.join
      end

      def inline_anchor_xref(node)
        matched = /^fn(:  (?<text>.*))?$/.match node.text
        f = matched.nil? ? "inline" : "footnote"
        c = matched.nil? ? node.text : matched[:text]
        t = node.target.gsub(/^#/, "").gsub(%r{(.)(\.xml)?#.*$}, "\\1")
          noko do |xml| 
          xml.xref c, **attr_code(target: t, type: f) 
        end.join
      end

      def inline_anchor_link(node)
        contents = node.text
        contents = nil if node.target.gsub(%r{^mailto:}, "") == node.text
        attributes = { "target": node.target }
        noko do |xml|
          xml.link contents, **attr_code(attributes)
        end.join
      end

      def inline_anchor_bibref(node)
        eref_contents = node.target == node.text ? nil : node.text
        eref_attributes = { id: node.target }
        @refids << node.target
        noko do |xml|
          xml.ref eref_contents, **attr_code(eref_attributes)
        end.join
      end

      def inline_callout(node)
        noko do |xml|
          xml.callout node.text
        end.join
      end

      def inline_footnote(node)
        noko do |xml|
          @fn_number += 1
          xml.fn **{reference: @fn_number} do |fn|
            fn.p { |p| p << node.text }
            footnote_style(node, node.text)
          end
        end.join("\n")
      end

      def inline_break(node)
        noko do |xml|
          xml << node.text
          xml.br
        end.join("\n")
      end

      def page_break(node)
        noko do |xml|
          xml << node.text
          xml.pagebreak
        end.join("\n")
      end

      def thematic_break(node)
        noko do |xml|
          xml << node.text
          xml.hr
        end.join("\n")
      end



      def inline_quoted(node)
        noko do |xml|
          case node.type
          when :emphasis then xml.em node.text
          when :strong then xml.strong node.text
          when :monospaced then xml.tt node.text
          when :double then xml << "\"#{node.text}\""
          when :single then xml << "'#{node.text}'"
          when :superscript then xml.sup node.text
          when :subscript then xml.sub node.text
          when :asciimath then xml.stem node.text, **{ type: "AsciiMath" }
          else
            case node.role
              # the following three are legacy, they are now handled by macros
            when "alt" then xml.admitted { |a| a << node.text }
            when "deprecated" then xml.deprecates { |a| a << node.text }
            when "domain" then xml.domain { |a| a << node.text }

            when "strike" then xml.strike node.text
            when "smallcap" then xml.smallcap node.text
            else
              xml << node.text
            end
          end
        end.join
      end

    end
  end
end