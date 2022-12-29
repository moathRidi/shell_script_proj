flag=1
to_save=()
count=0
savedF=1
while [ "$answer" != "-1" ] 
do
echo "r) read a dataset from a file"
echo "p) print the names of the features"
echo "l) encode a feature using lable encoding"
echo "o) encode a feature using one-hot encoding"
echo "m) apply MinMax scalling"
echo "s) save the processed dataset"
echo "e) exit"
read answer
echo ""
#check if the user entered any options before reading the dataset
if [ "$answer" = p ] || [ "$answer" = l ] || [ "$answer" = o ] || [ "$answer" = m ] || [ "$answer" = s ] && [ $flag -eq 1  ]
then 
echo " you must read the data set from the file first !"
else
if [ "$answer" = r ]
then 
echo "Please input the name of the dataset file"
echo ""
read fileName
echo ""
if [ -e "$fileName" ]
then 
data=$(cat "$fileName")

# Split the data into lines
lines=(${data//$'\n'/ })

# Split the first line (which contains the field names) into fields
fields=(${lines[0]//;/ })
to_save=$data
echo "$to_save" >> working.txt
# Check if the data is clean
for line in "${lines[@]:1}"; do
    # Split each line (which contains the field values) into values
    values=(${line//;/ })

    # Check if the number of fields in the line is equal to the number of field names
    if [ "${#values[@]}" -ne "${#fields[@]}" ]; then
        echo "The data is not clean: wrong number of fields"
        exit 1
    fi
    done
cat "$fileName"
echo " "
echo "read the file done sucssfully"
echo ""
flag=0   # label that the user read the file before

else
echo "file does not exist!"
fi
 # r is done here
elif [ "$answer" = p ]
then
read -r pheader < working.txt
echo "$pheader"

elif [ "$answer" = l ]
then

count=0
# Read the name of the categorical feature from the user
# Prompt the user for the name of the column to encode
read -p "Enter the name of the column to encode: " column
echo ""
read -r header < "$fileName"


# Get the index of the column
index=$(echo "$header" | tr ';' '\n' | grep -n "$column" | cut -d ':' -f 1)

# Check if the column was found
if [ -z "$index" ]; then
  echo " "
  echo "The name of categorical feature is wrong !"
  echo " "
  else


# Initialize a counter to use as the label for the first category
counter=0

# Initialize an empty array to store the categories
categories=()


# Read the data from the file
while read -r line; do
  # Skip the first line (header)
  if [ "$line" = "$header" ]; then
  echo "$line"
     to_save[0]=$line
     count=$(expr $count + 1)
     continue 
  fi

  # Get the value of the column in the current line
  value=$(echo "$line" | cut -d ';' -f "$index")
  # Check if the value is in the categories array
  found=0
  for category in "${categories[@]}"; do
    if [ "$value" = "$category" ]; then
      found=1
      break
    fi
  done
  if [ "$found" -eq 0 ]; then
    # If not, add it to the array and increment the counter
    categories+=("$value")
    ((counter++))
  fi
  # Replace the value in the line with the corresponding label
  label=$counter
  for ((i=0; i<${#categories[@]}; i++)); do
    if [ "$value" = "${categories[$i]}" ]; then
      label=$((i))
  break
    fi
  done
  line=$(echo "$line" | sed "s/$value/$label/")
  #keep updating the (to_save )array 
 to_save[$count]=$line 
  # Print the modified line
  count=$(expr $count + 1)
  echo "$line"
done < working.txt
> working.txt
echo " "
  for ((i=0; i<${#categories[@]}; i++)); do
echo "${categories[$i]} : $((i))" 
done

  for ((i=0; i<${#to_save[@]}; i++)); do
  echo "${to_save[$i]}" >> working.txt
  done 
echo " "
fi

elif [ "$answer" = o ]
then
count=0
to_save=()
# Read the first line of the file to get the column names
read -r header < "$fileName"
# Prompt the user for the name of the column to encode
read -p "Enter the name of the column to encode: " column
# Get the index of the column
index=$(echo "$header" | tr ';' '\n' | grep -n "$column" | cut -d ':' -f 1)
# Check if the column was found
if [ -z "$index" ]; then
echo " "
  echo "The name of categorical feature is wrong !"
  echo " "
  else                   # Initialize an empty array to store the categories
categories=()
 dataSet=()
 value=()
while read -r line; do                # Read the data from the file
  # Skip the first line (header)
  if [ "$line" = "$header" ]; then 
     first="$line"
    continue  
    fi
  value[$count]=$(echo "$line" | cut -d ';' -f "$index") # Get the value of the column in the current line
  found=0
  for category in "${categories[@]}"; do               # Check if the value is in the categories array
    if [ "${value[$count]}" = "$category" ]; then
      found=1
      break
      fi
 done
    if [ "$found" -eq 0 ]; then      # If not, add it to the array
       categories+=("${value[$count]}")                  
     fi
   dataSet[$count]="$line"
  count=$(expr $count + 1)   #add the counter 1
  
done < working.txt
> working.txt       #clear the previous data to print the new one
fLencode=""    #if it the last index remove the ;
for ((x=0; x<${#categories[@]}; x++)); do
      if [ $x -eq $(expr ${#categories[@]} - 1) ];then
      fLencode+="${categories[$x]}"          
      else 
       fLencode+="${categories[$x]};" 
    fi
  done #to change the first line (names) to encoded mode and print the line
  new_line=${first//$column/$fLencode}
  to_save[0]=$new_line
  echo "$new_line"       
for ((j=0; j<$count; j++)); do  # Initialize the one-hot encoded values
  encoded=""
  for ((i=0; i<${#categories[@]}; i++)); do
      if [ $i -lt $(expr ${#categories[@]} - 1) ];then         #if it the last index remove the ;     
         if [ "${value[$j]}" = "${categories[$i]}" ]; then
           encoded+="1;"
         else
           encoded+="0;" 
         fi
    else     
    if [ "${value[$j]}" = "${categories[$i]}" ]; then
           encoded+="1"
         else
           encoded+="0" 
         fi
    fi   
  done  
  # Replace the value in the line with the one-hot encoded values
  line=${dataSet[$j]//${value[$j]}/$encoded}  
  to_save[$((j+1))]=$line # Print the modified line
  echo "$line"
  done    
# Print the distinct values of the categorical feature and the corresponding labels
for ((i=0; i<${#categories[@]}; i++)); do
  echo "${categories[$i]}: $((i+1))"
done
 for ((i=0; i<${#to_save[@]}; i++)); do
  echo "${to_save[$i]}" >> working.txt   #updating to the working file content
  done
  fi
    #//////////////////////////////////////////////////////////////////////////////////////////////////////////#
elif [ "$answer" = m ]
then
# Read the first line of the file to get the column names
read -r Sheader < working.txt

# Prompt the user for the name of the column to encode
echo " "
read -p "please Enter the name of the feature to be scaled: " Scolumn
echo " "
# Get the index of the column
Sindex=$(echo "$Sheader" | tr ';' '\n' | grep -n "$Scolumn" | cut -d ':' -f 1)

# Check if the column was found
if [ -z "$Sindex" ]; then
echo " "
  echo "The name of categorical feature is wrong !"
  echo " "
else   # Read the data from the file
while read -r Sline; do
  # Skip the first line (header)
  if [ "$Sline" = "$Sheader" ]; then
  to_save[0]=$Sline
  firsts=$Sline
    continue
  fi
  # Get the value of the column in the current line
  Svalue=$(echo "$Sline" | cut -d ';' -f "$Sindex")
  # Check if the value is numeric
  if [[ -n "$Svalue" && "$Svalue" -ne 0 ]]; then
    # If it is, add it to the array
    Svalues+=("$Svalue")
    flag2=1
  else 
    flag2=0
  fi
done < working.txt
 # If it is not, print an error message and return to the main menu
if [ $flag2 -eq 0 ]
then 
echo " "
echo "This feature is a categorical feature and must be encoded first !"
echo " "
else
# Get the minimum and maximum values of the feature
min=$(echo "${Svalues[@]}" | tr ' ' '\n' | sort -n | head -n 1)
max=$(echo "${Svalues[@]}" | tr ' ' '\n' | sort -n | tail -n 1)

# Print the minimum and maximum values of the feature
echo "Minimum value: $min"
echo "Maximum value: $max"
echo " "
echo "$firsts"
echo " "
# Read the data from the file again
count=0
to_save=()
while read -r Sline; do
  # Skip the first line (header)
  if [ "$Sline" = "$Sheader" ]; then
   to_save[0]=$Sline
    count=$(expr $count + 1)   #add the counter 1
    continue
  fi
  # Get the value of the column in the current line
  Svalue=$(echo "$Sline" | cut -d ';' -f "$Sindex")

  # Calculate the scaled value
  scaled=$(expr "($Svalue - $min) / ($max - $min) " | bc -l)   # the bl-c command spisfy that the calculation should use floting point operation
  
  # Replace the value in the line with the scaled value
  estimated_scaled=$(printf "%.1f" "$scaled")
  Scline=${Sline//$Svalue/$estimated_scaled}
  to_save[$count]=$Scline
  # Print the scaled line to the screen
  echo "$Scline"
  echo " "
   count=$(expr $count + 1)   #add the counter 1
done < working.txt
> working.txt
for ((i=0; i<${#to_save[@]}; i++)); do
  echo "${to_save[$i]}" >> working.txt   #updating to the working file content
  done
fi
fi
elif [ "$answer" = e ]
then

if [ $savedF -eq 0 ]
then
echo "Are you sure you want to exit ? " 
echo "0) yes"
echo "1) No"
read dis
if [ "$dis" -ne 1 ]
then 
echo "Okye"
exit 1
fi

else
echo "the processed on dataset dose not saved , Are you sure want to exit ? "
echo "0) yes"
echo "1) No"
read dis
if [ "$dis" -ne 1 ]
then 
echo "Okye"
exit 1
fi

fi
elif [ "$answer" = s ]

then
read -p "please Enter the name of the file to save the processed dataset: " save_file
if [ -e "$save_file" ]   #check if the file dose not exist 
then
echo "this file is exist !"
else
for ((i=0; i<${#to_save[@]}; i++)); do  #print the current data to the new file
  echo "${to_save[$i]}" >> $save_file
done
savedF=0
fi

else
echo "Not on the list! "
fi
fi
done


#made by Moath ridi
#and Natalie dalalsheh
