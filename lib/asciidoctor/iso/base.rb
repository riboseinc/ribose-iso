require "date"
require "nokogiri"
require "htmlentities"
require "json"
require "pathname"
require "open-uri"
require "pp"
require "isodoc"

module Asciidoctor
  module ISO
    module Base
      Asciidoctor::Extensions.register do
        inline_macro Asciidoctor::ISO::AltTermInlineMacro
        inline_macro Asciidoctor::ISO::DeprecatedTermInlineMacro
        inline_macro Asciidoctor::ISO::DomainTermInlineMacro
      end

      def content(node)
        node.content
      end

      def skip(node, name = nil)
        name = name || node.node_name
        w = "converter missing for #{name} node in ISO backend"
        Utils::warning(node, w, nil)
        nil
      end

      def html_doc_path(file)
        File.join(File.dirname(__FILE__), File.join("html", file))
      end

      def doc_converter
        IsoDoc::Convert.new(
          htmlstylesheet: html_doc_path("htmlstyle.css"),
          wordstylesheet:  html_doc_path("wordstyle.css"),
          standardstylesheet: html_doc_path("isodoc.css"),
          header: html_doc_path("header.html"),
          htmlcoverpage: html_doc_path("html_iso_titlepage.html"),
          wordcoverpage: html_doc_path("word_iso_titlepage.html"),
          htmlintropage: html_doc_path("html_iso_intro.html"),
          wordintropage: html_doc_path("word_iso_intro.html"),
        )
      end

      def init
        @fn_number = 0
        @draft = false
        @refids = Set.new
        @anchors = {}
      end

      def document(node)
        init
        ret1 = makexml(node)
        ret = ret1.to_xml(indent: 2)
        filename = node.attr("docfile").gsub(/\.adoc/, ".xml").
          gsub(%r{^.*/}, '')
        File.open("#{filename}", "w") { |f| f.write(ret) }
        doc_converter.convert filename unless node.attr("nodoc")
        ret
      end

      def makexml(node)
        result = ["<?xml version='1.0' encoding='UTF-8'?>\n<iso-standard>"]
        @draft = node.attributes.has_key?("draft")
        result << noko { |ixml| front node, ixml }
        result << noko { |ixml| middle node, ixml }
        result << "</iso-standard>"
        result = textcleanup(result.flatten * "\n")
        ret1 = cleanup(Nokogiri::XML(result))
        ret1.root.add_namespace(nil, "http://riboseinc.com/isoxml")
        validate(ret1)
        ret1
      end

      def is_draft
        @draft
      end

      def front(node, xml)
        xml.bibdata **attr_code(type: node.attr("doctype")) do |b|
          metadata node, b
        end
        metadata_version(node, xml)
      end

      def middle(node, xml)
        xml.sections do |s|
          s << node.content if node.blocks?
        end
      end

      def add_term_source(xml_t, seen_xref, m)
        attr = { bibitemid: seen_xref.children[0]["target"],
                 format: seen_xref.children[0]["format"],
                 type: "inline" }
        xml_t.origin seen_xref.children[0].content, **attr_code(attr)
        m[:text] && xml_t.modification do |mod| 
          mod.p { |p| p << m[:text].sub(/^\s+/, "")  }
        end
      end

      TERM_REFERENCE_RE_STR = <<~REGEXP.freeze
             ^(?<xref><xref[^>]+>([^<]*</xref>)?)
               (,\s(?<text>.*))?
             $
      REGEXP
      TERM_REFERENCE_RE =
        Regexp.new(TERM_REFERENCE_RE_STR.gsub(/\s/, "").gsub(/_/, "\\s"),
                   Regexp::IGNORECASE | Regexp::MULTILINE)


      def extract_termsource_refs(text, node)
        matched = TERM_REFERENCE_RE.match text
        if matched.nil?
          Utils::warning(node, "term reference not in expected format", text)
        end
        matched
      end

      def termsource(node)
        matched = extract_termsource_refs(node.content, node) or return
        noko do |xml|
          attrs = { status: matched[:text] ? "identical" : "modified" }
          xml.termsource **attrs do |xml_t|
            seen_xref = Nokogiri::XML.fragment(matched[:xref])
            add_term_source(xml_t, seen_xref, matched)
            style(node, matched[:text])
          end
        end.join("\n")
      end

    end
  end
end
