#!/bin/bash
# Create a Write document from a PDF by generating page images

verifyPdf() {
  if [ -z "$1" ] # verify argument isn't empty
  then
    return 1
  fi

  if ! [[ $1 =~ \.pdf$ ]]; # verify argument is a pdf
  then
    echo "Ignoring $1 as it is not a PDF file"
    return 1
  fi

  if [ ! -f "$1" ]; # verify argument exists
  then
    echo "Ignoring $1 as it does not exist"
    return 1
  fi

  return 0
}

pdf2images() {
  (command -v pdftoppm >/dev/null 2>&1 && pdftoppm -png -r 300 "$1" out) || convert -density 300 -scene 1 "$1" out-%03d.png
  if [ ! -f "out-1.png" ] && [ ! -f "out-01.png" ] && [ ! -f "out-001.png" ]; then
    echo "No page images found: make sure pdftoppm (from poppler-utils) or imagemagick and ghostscript are installed"
    exit 1
  fi
}

images2write() {
  printf '<svg id="write-document" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n' > "$1"
  printf '<rect id="write-doc-background" width="100%%" height="100%%" fill="#808080"/>\n' >> "$1"

  local pngpage
  for pngpage in out-*.png
  do
    local width2
    local height2
    read width2 height2 < <(file $pngpage | cut -d "," -f 2 | cut -d " " -f 2,4)
    # page images generated at 300 DPI but Write uses 150 DPI as reference
    local width=$((width2/2))
    local height=$((height2/2))

    printf '<svg class="write-page" color-interpolation="linearRGB" x="10" y="10" width="%dpx" height="%dpx" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">\n' $width $height >> "$1"
    printf '  <g class="write-content write-v3" xruling="0" yruling="40" marginLeft="100" papercolor="#FFFFFF" rulecolor="#9F0000FF">\n' >> "$1"
    printf '    <g class="ruleline write-no-dup" shape-rendering="crispEdges">\n' >> "$1"
    printf '      <rect class="pagerect" fill="#FFFFFF" stroke="none" x="0" y="0" width="%d" height="%d" />\n' $width $height >> "$1"
    [ "$FOREGROUND" = true ] && printf '    </g>\n' >> "$1"  # end ruleline <g>
    printf '      <image x="0" y="0" width="%d" height="%d" xlink:href="data:image/png;base64,' $width $height >> "$1"


    # doesn't seem to be a way to prevent base64 from appending newline
    base64 $pngpage | tr -d '\n' >> "$1"
    printf '"/>\n' >> "$SVGOUT" # end <image>
    [ "$FOREGROUND" = true ] || printf '    </g>\n' >> "$SVGOUT"  # end ruleline <g>
    printf '  </g>\n</svg>' >> "$SVGOUT"  # end content <g> and page
  done

  printf "\n</svg>" >> "$1"
  [ "$COMPRESS" = true ] && gzip -S z "$SVGOUT" && SVGOUT="$SVGOUT"z
  rm out-*.png
}


# Main

FOREGROUND=false
COMPRESS=true
PDFSIN=()
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
    #-d|--dpi)
      #DPI="$2"
      #shift # past argument
      #shift # past value
      #;;
    -*|--*)
      echo "Invalid option '$key', ignoring"
      shift # past argument
      ;;
    *)    # unknown option
      shift # past argument
      if verifyPdf "$key"
      then
        PDFSIN+=("$key")
      fi
      ;;
  esac
done

if [ ${#PDFSIN[@]} -eq 0 ]
then
  echo "pdf2write.sh: Convert PDF to svg document for Stylus Labs Write"
  echo "Usage: pdf2write.sh [options] [PDF-file]"
  echo "  -f,--fg,--foreground: place page images in editable layer instead of ruling layer"
  echo "  --nozip: generate uncompressed svg instead of svgz"
  exit 1
fi

for PDF in "${PDFSIN[@]}"
do
  echo "Converting $PDF to images..."
  pdf2images "$PDF"

  echo "Generating Write document..."
  SVGOUT=$(basename "$PDF" pdf)svg
  images2write "$SVGOUT"
  echo "Finished creating ${SVGOUT}"
done
