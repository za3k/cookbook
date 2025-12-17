# Original cookbook contained these characters:
#  -abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()/%: .\n+,&[]=?~'*"!@°½⅓¼⅛⅔¾
#  That is, tr </home/zachary/documents/cookbook.txt -d "\-a-zA-Z0-9()/%: .\n+,&[]=?~'*\"\!@°½⅓¼⅛⅔¾" | wc -c returns 0
# Turns out these characters fuck up my printer: ⅛⅔¾

# Split the pages
rm -rf tmp-txt
mkdir -p tmp-txt

# Remove the note at the very end, convert fractions etc
cat ./cookbook.txt \
  | sed -e "s|1/8|⅛|g" \
  | sed -e "s|1/4|¼|g" \
  | sed -e "s|1/3|⅓|g" \
  | sed -e "s|1/2|½|g" \
  | sed -e "s|2/3|⅔|g" \
  | sed -e "s|'F|°F|g" \
  | sed -e "s|'C|°C|g" \
  | head -n-3 \
  >tmp-cookbook-full.txt
sed <tmp-cookbook-full.txt -ze "s/===\n/\x00/g" | split - tmp-txt/cookbook- -d --lines 1 -t '\0'
for x in tmp-txt/*; do
  tr <${x} -d '\000' >/tmp/a
  mv /tmp/a ${x}
done

# Note: cookbook should be limited to 55 columns
# Check width
MAX_LENGTH=$(wc -L tmp-txt/* | tail -n1 | awk '{print $1}')
if [ "$MAX_LENGTH" -gt 55 ]; then 
  echo "Cookbook too wide (limit is 55)"
  for x in tmp-txt/*; do
    LENGTH=$(wc -L "$x" | tail -n1 | awk '{print $1}')
    if [ "$LENGTH" -gt 55 ]; then
      head -n1 "$x"
    fi
  done
  exit 2
fi

# What's the max limit on page height? At least 40, let's say 40?

# Generate .ps files for each txt file
rm -rf tmp-ps tmp-ps-a5
mkdir -p tmp-ps tmp-ps-a5
for x in tmp-txt/*; do
  paps --paper letter --top-margin=50 --font "DejaVuSansMono 14" -o tmp-ps/$(basename ${x}).ps <${x}
  #paps --paper 45 --top-margin=50 --font "DejaVuSansMono 14" -o tmp-ps-a5/$(basename ${x}).ps <${x}
done

# Combine the .ps files
rm -rf tmp-cookbook-big.ps
find tmp-ps -type f | sort | xargs psjoin >tmp-cookbook-big.ps
pstops -Pletter -pA5 '1:0@0.686(0,0)' <tmp-cookbook-big.ps >tmp-cookbook-a5.ps

#rm -rf tmp-cookbook-a5.ps

# Make a tiny book, 4 pages per sheet
# Original, 1 sheet = 4 pages per signature
#pstops -Pletter -pletter 4:1,2,3,0 <tmp-cookbook-big.ps >tmp-cookbook-shuffled.ps
# New, 4 sheets = 16 pages per signature
pstops -Pletter -pletter 16:15,0,1,14,13,2,3,12,11,4,5,10,9,6,7,8 <tmp-cookbook-big.ps >tmp-cookbook-shuffled.ps
psnup -2 -Pletter -pletter -d <tmp-cookbook-shuffled.ps >cookbook.ps

# Generate PDF files
ps2pdf tmp-cookbook-big.ps cookbook-big.pdf
ps2pdf -sPAPERSIZE=a5 tmp-cookbook-a5.ps cookbook-a5.pdf
ps2pdf cookbook.ps cookbook-small.pdf

echo
echo "To print run:"
echo "cat cookbook.ps | ssh pi-printer PRINTER=HL2270DW lp -o sides=two-sided-short-edge -o media=letter"
