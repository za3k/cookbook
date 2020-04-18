# Original cookbook contained these characters:
#  -abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789()/%: .\n+,&[]=?~'*"!@°½⅓¼⅛⅔¾
#  That is, tr </home/zachary/documents/cookbook-2020.txt -d "\-a-zA-Z0-9()/%: .\n+,&[]=?~'*\"\!@°½⅓¼⅛⅔¾" | wc -c returns 0
# Turns out these characters fuck up my printer: ⅛⅔¾


# Split the pages
rm -rf tmp-txt
mkdir -p tmp-txt
cat /home/zachary/documents/cookbook-2020.txt \
  | sed -e "s|1/8|⅛|g" \
  | sed -e "s|1/4|¼|g" \
  | sed -e "s|1/3|⅓|g" \
  | sed -e "s|1/2|½|g" \
  | sed -e "s|2/3|⅔|g" \
  | sed -e "s|'F|°F|g" \
  | sed -e "s|'C|°C|g" >tmp-cookbook-2020-full.txt
sed <tmp-cookbook-2020-full.txt -ze "s/===\n/\x00/g" | split - tmp-txt/cookbook- -d --lines 1 -t '\0'
for x in tmp-txt/*; do
  tr <${x} -d '\000' >/tmp/a
  mv /tmp/a ${x}
done

# Remove the one page which is too big
#mv /tmp/cookbook-03 too-big-page
rm tmp-txt/cookbook-03

# Note: cookbook should be limited to 55 columns
# Check width
MAX_LENGTH=$(wc -L tmp-txt/* | tail -n1 | awk '{print $1}')
[ 55 -ge "$MAX_LENGTH" ] || {
  echo "Cookbook too wide"
  exit 2
}

# Generate .ps files for each txt file
rm -rf tmp-ps
mkdir -p tmp-ps
for x in tmp-txt/*; do
  paps --paper letter --top-margin=50 --font "DejaVuSansMono 14" -o tmp-ps/$(basename ${x}).ps <${x}
done

# Combine the .ps files
rm -rf tmp-cookbook-big.ps
find tmp-ps -type f | sort | xargs psjoin >tmp-cookbook-big.ps
#find tmp-txt -type f | sort | cat >cookbook.txt

# Make a tiny book, 4 pages per sheet
pstops -Pletter -pletter 4:1,2,3,0 <tmp-cookbook-big.ps >tmp-cookbook-shuffled.ps
psnup -2 -pletter -Pletter -d <tmp-cookbook-shuffled.ps >cookbook.ps
#rm -rf tmp-*

echo
echo "To print run:"
echo "cat cookbook.ps | ssh avalanche PRINTER=HL2270DW lp -o sides=two-sided-short-edge -o media=letter"
