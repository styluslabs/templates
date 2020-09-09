#!/bin/bash
# Create a Write document from a PDF by generating page images

pdf2images() {
  (command -v pdftoppm >/dev/null 2>&1 && pdftoppm -png -r 300 $1 out) || convert -density 300 -scene 1 $1 out-%03d.png
  if [ ! -f "out-1.png" ] && [ ! -f "out-01.png" ] && [ ! -f "out-001.png" ]; then
    echo "No page images found: make sure pdftoppm (from poppler-utils) or imagemagick and ghostscript are installed"
    exit 1
  fi
}

images2write() {
  printf '<svg id="write-document" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n' > $1
  printf '<rect id="write-doc-background" width="100%%" height="100%%" fill="#808080"/>\n' >> $1

  local pngpage
  for pngpage in out-*.png
  do
    local width2
    local height2
    read width2 height2 < <(file $pngpage | cut -d "," -f 2 | cut -d " " -f 2,4)
    # page images generated at 300 DPI but Write uses 150 DPI as reference
    local width=$((width2/2))
    local height=$((height2/2))

    printf '<svg class="write-page" color-interpolation="linearRGB" x="10" y="10" width="%dpx" height="%dpx" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n' $width $height >> $1
    printf '  <g class="write-content write-v3" xruling="0" yruling="40" marginLeft="100" papercolor="#FFFFFF" rulecolor="#9F0000FF">\n' >> $1
    printf '    <g class="ruleline write-no-dup" shape-rendering="crispEdges">\n' >> $1
    printf '      <rect class="pagerect" fill="#FFFFFF" stroke="none" x="0" y="0" width="%d" height="%d" />\n' $width $height >> $1

    printf '      <image x="0" y="0" width="%d" height="%d" xlink:href="data:image/png;base64,' $width $height >> $1
    # doesn't seem to be a way to prevent base64 from appending newline
    base64 $pngpage | tr -d '\n' >> $1
    printf '"/>\n    </g>\n  </g>\n</svg>' >> $1
  done

  printf "\n</svg>" >> $1

  gzip -S z $1
  rm out-*.png
}


# Main

if [ $# -eq 0 ]; then
  echo "No arguments provided. Please specify a PDF to convert with 'pdf2write.sh /path/to/foo.pdf'"
  exit 0
fi

for PDF in "$@"
do
  # verify argument isn't empty
  if [ -z "$PDF" ]
  then
    continue
  fi

  echo "Converting $PDF to images..."
  pdf2images $PDF

  echo "Generating Write document..."
  SVGOUT=$(basename $PDF pdf)svg
  images2write $SVGOUT
  echo "Finished creating ${SVGOUT}z"
done
