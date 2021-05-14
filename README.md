## Document templates for [Stylus Labs Write](http://www.styluslabs.com/) ##

### How to use in Write ###

Download the template to your desired folder, then in Write long press on the template file and choose "Open Copy" (in iOS, long press and choose "Duplicate", then rename and open).  Alternatively, the template can be opened directly and then a copy saved using Document -> Save As...

To add a page with a different template to a document, use Document -> Insert Document... and choose the desired template.


### PDF import ###

On Linux or Mac, `pdf2write.sh` can convert PDF to SVG for use in Write.  First try with the `--vector` argument (requires poppler-utils to be installed).  When opening in Write, choose "Use as background" unless you want to modify the original content.  If the results are not satisfactory, try again without `--vector` to render pages to images instead (requires imagemagick and ghostscript or pdftoppm from poppler-utils).  Another option using inkscape is [kosmospredanie/pdftowrite](https://github.com/kosmospredanie/pdftowrite).

For LaTeX documents, [dvisvgm](https://dvisvgm.de) produces good results converting directly from DVI: `dvisvgm -p1- -bpapersize --stdout in.dvi > out.svg`


### Editing templates ###

Simple templates can be editing by manually editing the SVG file (as text).  It should be possible to edit templates in, e.g., Inkscape, but this isn't tested yet.  Send a pull request if you'd like to share your template.

Example w/ explanation:

```
<svg id="write-document" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
<rect id="write-doc-background" width="100%" height="100%" fill="#808080"/>

<svg class="write-page" color-interpolation="linearRGB" x="10" y="10" width="768px" height="1050px" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
  <g class="write-content write-v3" width="768" height="1050" xruling="0" yruling="10" marginLeft="0" papercolor="#FFFFFF" rulecolor="#FF000000">
    <g class="ruleline write-scale-down" color="#000000" shape-rendering="crispEdges" vector-effect="non-scaling-stroke">
      <pattern id="ruling1" x="0" y="50" width="768" height="100" patternUnits="userSpaceOnUse">
        <path fill="none" stroke="currentColor" stroke-width="1" d="M68 10 l632 0" />
        <path fill="none" stroke="currentColor" stroke-width="1" d="M68 20 l632 0" />
        <path fill="none" stroke="currentColor" stroke-width="1" d="M68 30 l632 0" />
        <path fill="none" stroke="currentColor" stroke-width="1" d="M68 40 l632 0" />
        <path fill="none" stroke="currentColor" stroke-width="1" d="M68 50 l632 0" />
      </pattern>
      <rect class="pagerect" fill="#FFFFFF" x="0" y="0" width="768" height="1050" />
      <rect fill="url(#ruling1)" x="0" y="50" width="768" height="4096" />
    </g>
  </g>
</svg>

</svg>
```

The page background ("ruling") is determined by the content in `g.ruleline`.  `currentColor` inserts the color specified in the nearest `color` attribute (standard SVG behavior) - the `color` attribute on `g.ruleline` is set from the "Ruling Color" chosen in the Page Setup dialog.  Fixed colors are specified directly, e.g., `stroke="red"` or `stroke="#FF0000"`. `shape-rendering="crispEdges"` gives thin lines a sharp appearance and `vector-effect="non-scaling-stroke"` prevents them from changing size when zooming in or out, while the class `write-scale-down` causes Write to lighten them when zooming out so they don't dominate the appearance when zoomed far out.  Using a `<pattern>` enables changing page size for simple repeated rulings, up to the size of the `<rect>` filled with the pattern.

On `g.write-content`, the `width`, `height`, `xruling`, `yruling`, `marginLeft`, `papercolor`, and `rulecolor` attributes correspond to the values set in the Page Setup dialog.  Page width, height, and color (as `fill`) must also be set on `rect.pagerect` in `g.ruleline`.  Page width and height are also set on `svg.write-page`.

Any content inside `g.write-content` after `g.ruleline` will be editable in Write.

Multi-page templates can be created by adding additional pages (svg.write-page) to the template document.  When editing the document in Write, the background of the last page will be duplicated when adding to new pages to the end.  To prevent this, the class `write-no-dup` can be added to `g.ruleline`
