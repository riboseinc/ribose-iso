require "spec_helper"

RSpec.describe Asciidoctor::ISO do
  it "processes inline_quoted formatting" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :iso, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      _emphasis_
      *strong*
      `monospace`
      "double quote"
      'single quote'
      super^script^
      sub~script~
      stem:[a_90]
      [alt]#alt#
      [deprecated]#deprecated#
      [domain]#domain#
      [strike]#strike#
      [smallcap]#smallcap#
    INPUT
            #{BLANK_HDR}
       <sections>
         <em>emphasis</em>
       <strong>strong</strong>
       <tt>monospace</tt>
       "double quote"
       'single quote'
       super<sup>script</sup>
       sub<sub>script</sub>
       <stem type="AsciiMath">a_90</stem>
       <admitted>alt</admitted>
       <deprecates>deprecated</deprecates>
       <domain>domain</domain>
       <strike>strike</strike>
       <smallcap>smallcap</smallcap>
       </sections>
       </iso-standard>
    OUTPUT
  end

  it "processes breaks" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :iso, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      Line break +
      line break

      '''

      <<<
    INPUT
            #{BLANK_HDR}
       <sections><p id="_">Line break<br/>
       line break</p>
       <hr/>
       <pagebreak/></sections>
       </iso-standard>
    OUTPUT
  end

  it "processes links" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :iso, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      mailto:fred@example.com
      http://example.com[]
      http://example.com[Link]
    INPUT
            #{BLANK_HDR}
       <sections>
         <p id="_">mailto:fred@example.com
       <link target="http://example.com"/>
       <link target="http://example.com">Link</link></p>
       </sections>
       </iso-standard>
    OUTPUT
  end

    it "processes bookmarks" do
    expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :iso, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      Text [[bookmark]] Text
    INPUT
            #{BLANK_HDR}
       <sections>
         <p id="_">Text <bookmark id="bookmark"/> Text</p>
       </sections>
       </iso-standard>
    OUTPUT
    end

    it "processes crossreferences" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :iso, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [[reference]]
      == Section

      Inline Reference to <<reference>>
      Footnoted Reference to <<reference,fn>>
      Inline Reference with Text to <<reference,text>>
      Footnoted Reference with Text to <<reference,fn: text>>
    INPUT
       #{BLANK_HDR}
        <sections>
         <clause id="reference" inline-header="false" obligation="normative">
         <title>Section</title>
         <p id="_">Inline Reference to <xref target="reference"/>
       Footnoted Reference to <xref target="reference"/>
       Inline Reference with Text to <xref target="reference">text</xref>
       Footnoted Reference with Text to <xref target="reference">text</xref></p>
       </clause>
       </sections>
       </iso-standard>
      OUTPUT
    end

    it "processes bibliographic anchors" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :iso, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      [bibliography]
      == Normative References

      * [[[ISO712,x]]] Reference
      * [[[ISO713]]] Reference

    INPUT
            #{BLANK_HDR}
       <sections>

       </sections><references id="_" obligation="informative">
         <title>Normative References</title>
         <bibitem id="ISO712">
         <formattedref format="application/x-isodoc+xml">Reference</formattedref>
         <docidentifier>x</docidentifier>
       </bibitem>
         <bibitem id="ISO713">
         <formattedref format="application/x-isodoc+xml">Reference</formattedref>
         <docidentifier>ISO713</docidentifier>
       </bibitem>
       </references>
       </iso-standard>
    OUTPUT
  end

  it "processes footnotes" do
      expect(strip_guid(Asciidoctor.convert(<<~"INPUT", backend: :iso, header_footer: true))).to be_equivalent_to <<~"OUTPUT"
      #{ASCIIDOC_BLANK_HDR}
      Hello!footnote:[Footnote text]
    INPUT
            #{BLANK_HDR}
       <sections>
         <p id="_">Hello!<fn reference="1">
         <p id="_">Footnote text</p>
       </fn></p>
       </sections>
       </iso-standard>
    OUTPUT
  end


end