#!/bin/bash
# Create a Write document from a PDF by generating page images

FOREGROUND=false
COMPRESS=true
VECTOR=false
PDFIN=''
# https://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
  -f|--fg|--foreground)
  FOREGROUND=true
  shift # past argument
  ;;
  --nozip)
  COMPRESS=false
  shift # past argument
  ;;
  --vector)
  VECTOR=true
  shift # past argument
  ;;
  #-d|--dpi)
  #DPI="$2"
  #shift # past argument
  #shift # past value
  #;;
  *)    # unknown option
  PDFIN="$1"
  shift # past argument
  ;;
esac
done

if [ -z "$PDFIN" ]
then
  echo "pdf2write.sh: Convert PDF to svg document for Stylus Labs Write"
  echo "Usage: pdf2write.sh [options] [PDF-file]"
  echo "  -f,--fg,--foreground: place page images in editable layer instead of ruling layer"
  echo "  --nozip: generate uncompressed svg instead of svgz"
  echo "  --vector: convert to vectors instead of images (-f does not apply)"
  exit 1
fi

SVGOUT=$(basename "$PDFIN" pdf)svg

# if not passed -f, -l args, pdftocairo will generate a single svg file using <pageSet> and <page>, which is
#  not supported by Write (yet), and will never be supported by browsers
if [ "$VECTOR" = true ]
then
  pdftocairo -svg -f 1 -l 1 "$PDFIN" - > "$SVGOUT"
  for i in {2..1000}; do pdftocairo -svg -f "${i}" -l "${i}" "$PDFIN" - || break ; done >> "$SVGOUT" 2>/dev/null
  [ "$COMPRESS" = true ] && gzip -S z "$SVGOUT"
  echo "Finished creating $SVGOUT"z
  exit 0
fi
# another option, but poor results w/ non-LaTeX pdfs: dvisvgm --pdf -p1- --stdout in.pdf > out.svg

echo "Converting $PDFIN to images..."
(command -v pdftoppm >/dev/null 2>&1 && pdftoppm -png -r 300 "$PDFIN" out) || convert -density 300 -scene 1 "$PDFIN" out-%03d.png
if [ ! -f "out-1.png" ] && [ ! -f "out-01.png" ] && [ ! -f "out-001.png" ]; then
  echo "No page images found: make sure pdftoppm (from poppler-utils) or imagemagick and ghostscript are installed"
  exit 2
fi
echo "Generating Write document..."

printf '<svg id="write-document" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n' > "$SVGOUT"
printf '<rect id="write-doc-background" width="100%%" height="100%%" fill="#808080"/>\n' >> "$SVGOUT"

for PNGPAGE in out-*.png
do
  read WIDTH2 HEIGHT2 < <(file $PNGPAGE | cut -d "," -f 2 | cut -d " " -f 2,4)
  # page images generated at 300 DPI but Write uses 150 DPI as reference
  WIDTH=$((WIDTH2/2))
  HEIGHT=$((HEIGHT2/2))

  printf '<svg class="write-page" color-interpolation="linearRGB" x="10" y="10" width="%dpx" height="%dpx" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n' $WIDTH $HEIGHT >> "$SVGOUT"
  printf '  <g class="write-content write-v3" xruling="0" yruling="40" marginLeft="100" papercolor="#FFFFFF" rulecolor="#9F0000FF">\n' >> "$SVGOUT"
  printf '    <g class="ruleline write-no-dup" shape-rendering="crispEdges">\n' >> "$SVGOUT"
  printf '      <rect class="pagerect" fill="#FFFFFF" stroke="none" x="0" y="0" width="%d" height="%d" />\n' $WIDTH $HEIGHT >> "$SVGOUT"
  [ "$FOREGROUND" = true ] && printf '    </g>\n' >> "$SVGOUT"  # end ruleline <g>
  printf '      <image x="0" y="0" width="%d" height="%d" xlink:href="data:image/png;base64,' $WIDTH $HEIGHT >> "$SVGOUT"
  # doesn't seem to be a way to prevent base64 from appending newline
  base64 $PNGPAGE | tr -d '\n' >> "$SVGOUT"
  printf '"/>\n' >> "$SVGOUT" # end <image>
  [ "$FOREGROUND" = true ] || printf '    </g>\n' >> "$SVGOUT"  # end ruleline <g>
  printf '  </g>\n</svg>' >> "$SVGOUT"  # end content <g> and page
done

printf "\n</svg>" >> "$SVGOUT"

[ "$COMPRESS" = true ] && gzip -S z "$SVGOUT"
rm out-*.png
echo "Finished creating $SVGOUT"z
